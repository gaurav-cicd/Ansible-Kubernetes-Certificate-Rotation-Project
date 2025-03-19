#!/bin/bash

# Configuration
PROJECT_PATH="/path/to/your/project"
LOG_FILE="/var/log/cert-monitor.log"
LOCK_FILE="/var/run/cert-monitor.lock"
MAX_RETRIES=3
RETRY_DELAY=60
HEALTH_CHECK_INTERVAL=300  # 5 minutes

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check if another instance is running
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_message "Another instance is already running (PID: $pid)"
            exit 1
        else
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

# Function to clean up lock file
cleanup() {
    rm -f "$LOCK_FILE"
    log_message "Cleanup completed"
}

# Function to check monitoring health
check_monitoring_health() {
    log_message "Running monitoring health check"
    
    # Check service status
    if ! systemctl is-active --quiet ansible-cert-monitor.service; then
        log_message "ERROR: Monitoring service is not running"
        return 1
    fi
    
    # Check timer status
    if ! systemctl is-active --quiet ansible-cert-monitor.timer; then
        log_message "ERROR: Monitoring timer is not active"
        return 1
    fi
    
    # Check for recent errors in logs
    if tail -n 100 "$LOG_FILE" | grep -iE "error|failed|exception" > /dev/null; then
        log_message "ERROR: Recent errors detected in logs"
        return 1
    fi
    
    # Check last execution time
    last_execution=$(systemctl show ansible-cert-monitor.service -p ExecMainStartTimestamp | cut -d= -f2)
    if [ -n "$last_execution" ]; then
        last_execution_epoch=$(date -d "$last_execution" +%s)
        current_epoch=$(date +%s)
        if [ $((current_epoch - last_execution_epoch)) -gt 300 ]; then
            log_message "ERROR: Service has been running for more than 5 minutes"
            return 1
        fi
    fi
    
    return 0
}

# Function to run health check playbook
run_health_check() {
    log_message "Running health check playbook"
    if ! ansible-playbook "$PROJECT_PATH/playbooks/check_monitoring_health.yml" >> "$LOG_FILE" 2>&1; then
        log_message "ERROR: Health check playbook failed"
        return 1
    fi
    return 0
}

# Main monitoring function
run_monitoring() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        log_message "Starting certificate monitoring check"
        
        # Run the Ansible playbook
        if ansible-playbook "$PROJECT_PATH/playbooks/monitor_certificates.yml" >> "$LOG_FILE" 2>&1; then
            log_message "Certificate monitoring completed successfully"
            return 0
        else
            retry_count=$((retry_count + 1))
            log_message "Certificate monitoring failed (Attempt $retry_count of $MAX_RETRIES)"
            
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log_message "Waiting $RETRY_DELAY seconds before retry"
                sleep $RETRY_DELAY
            fi
        fi
    done
    
    log_message "Certificate monitoring failed after $MAX_RETRIES attempts"
    return 1
}

# Main execution
check_lock

# Run monitoring
run_monitoring

# Check monitoring health
if ! check_monitoring_health; then
    log_message "Monitoring health check failed, running health check playbook"
    run_health_check
fi

# Set up periodic health checks
while true; do
    sleep $HEALTH_CHECK_INTERVAL
    if ! check_monitoring_health; then
        log_message "Periodic health check failed, running health check playbook"
        run_health_check
    fi
done 