# Kubernetes Certificate Rotation with Ansible

This Ansible project automates the process of rotating Kubernetes certificates that are stored in Hashicorp Vault. The project includes monitoring, notification, and rotation capabilities.

## Prerequisites

- Ansible 2.9 or higher
- Hashicorp Vault access
- Kubernetes cluster access
- Slack webhook URL (for notifications)
- Splunk monitoring setup
- Systemd-based Linux system (for automatic monitoring)

## Project Structure

```
.
├── inventory/
│   └── hosts.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── certificate_monitor/
│   │   └── tasks/
│   │       └── main.yml
│   ├── certificate_rotation/
│   └── notification/
│       └── tasks/
│           ├── slack.yml
│           └── email.yml
├── playbooks/
│   ├── rotate_certificates.yml
│   ├── monitor_certificates.yml
│   └── setup_monitoring.yml
├── monitor_certificates.sh
├── ansible-cert-monitor.service
└── requirements.yml
```

## Configuration

1. Update `inventory/hosts.yml` with your Kubernetes cluster details
2. Configure variables in `group_vars/all.yml`:
   - Vault credentials
   - Slack webhook URL
   - Certificate paths
   - Notification settings
   - Email configuration (if using email notifications)

## Usage

### Manual Certificate Monitoring
```bash
ansible-playbook playbooks/monitor_certificates.yml
```

### Certificate Rotation
```bash
ansible-playbook playbooks/rotate_certificates.yml
```

### Setting Up Automatic Monitoring

1. Update the `PROJECT_PATH` in `monitor_certificates.sh` to point to your project directory.

2. Run the setup playbook:
```bash
ansible-playbook playbooks/setup_monitoring.yml
```

This will:
- Create necessary log files and directories
- Install the monitoring script
- Set up a systemd service and timer
- Enable and start the monitoring service

### Monitoring Service Management

Check service status:
```bash
# Check service status
systemctl status ansible-cert-monitor.service

# Check timer status
systemctl status ansible-cert-monitor.timer

# View logs
tail -f /var/log/cert-monitor.log
```

Control the monitoring service:
```bash
# Stop monitoring
sudo systemctl stop ansible-cert-monitor.timer

# Start monitoring
sudo systemctl start ansible-cert-monitor.timer

# Disable monitoring
sudo systemctl disable ansible-cert-monitor.timer

# Enable monitoring
sudo systemctl enable ansible-cert-monitor.timer
```

## Features

- Automated certificate monitoring via Splunk and direct Vault validation
- Automatic monitoring every 5 minutes using systemd timer
- Slack and email notifications 5 days before certificate expiration
- Automated certificate rotation using Ansible
- Team notification after successful rotation
- Integration with Hashicorp Vault for secure certificate storage
- Comprehensive logging and error handling
- Automatic retry mechanism for failed checks
- Prevention of multiple monitoring instances

## Monitoring System Details

The monitoring system includes:

1. **Automatic Execution**:
   - Runs every 5 minutes using systemd timer
   - Starts automatically on system boot
   - Handles failures and retries

2. **Error Handling**:
   - Retries up to 3 times on failure
   - 60-second delay between retries
   - Prevents multiple instances from running simultaneously

3. **Logging**:
   - Logs all activities to `/var/log/cert-monitor.log`
   - Includes timestamps and detailed error messages
   - Maintains execution history

4. **Dual Monitoring Approach**:
   - Direct certificate validation from Hashicorp Vault
   - Splunk integration for additional monitoring and historical data
   - Combined results for comprehensive certificate status

## Security Considerations

- All sensitive credentials are stored in Hashicorp Vault
- Certificate rotation is performed with minimal downtime
- Audit logging of all certificate operations
- Secure handling of monitoring service credentials
- Proper file permissions for logs and scripts
