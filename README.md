<<<<<<< HEAD
# Ansible-Kubernetes-Certificate-Rotation-Project
=======
# Kubernetes Certificate Rotation with Ansible

This Ansible project automates the process of rotating Kubernetes certificates that are stored in Hashicorp Vault. The project includes monitoring, notification, and rotation capabilities.

## Prerequisites

- Ansible 2.9 or higher
- Hashicorp Vault access
- Kubernetes cluster access
- Slack webhook URL (for notifications)
- Splunk monitoring setup

## Project Structure

```
.
├── inventory/
│   └── hosts.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── certificate_monitor/
│   ├── certificate_rotation/
│   └── notification/
├── playbooks/
│   ├── rotate_certificates.yml
│   └── send_notification.yml
└── requirements.yml
```

## Configuration

1. Update `inventory/hosts.yml` with your Kubernetes cluster details
2. Configure variables in `group_vars/all.yml`:
   - Vault credentials
   - Slack webhook URL
   - Certificate paths
   - Notification settings

## Usage

1. Monitor certificates:
   ```bash
   ansible-playbook playbooks/monitor_certificates.yml
   ```

2. Rotate certificates:
   ```bash
   ansible-playbook playbooks/rotate_certificates.yml
   ```

## Features

- Automated certificate monitoring via Splunk
- Slack notifications 5 days before certificate expiration
- Automated certificate rotation using Ansible
- Team notification after successful rotation
- Integration with Hashicorp Vault for secure certificate storage

## Security Considerations

- All sensitive credentials are stored in Hashicorp Vault
- Certificate rotation is performed with minimal downtime
- Audit logging of all certificate operations 
>>>>>>> 6a32661 (Initial commit)
