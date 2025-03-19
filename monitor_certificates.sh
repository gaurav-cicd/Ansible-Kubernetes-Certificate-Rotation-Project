#!/bin/bash

# Configuration
PROJECT_PATH="/path/to/your/project"
LOG_FILE="/var/log/cert-monitor.log"
LOCK_FILE="/var/run/cert-monitor.lock"
MAX_RETRIES=3
RETRY_DELAY=60

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

# Set up trap for cleanup
trap cleanup EXIT

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
run_monitoring 