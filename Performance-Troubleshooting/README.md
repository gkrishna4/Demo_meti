# Advanced Performance Troubleshooting Toolkit

Comprehensive Ansible playbooks and shell scripts for diagnosing and resolving performance issues in production Linux environments.

## Overview

This toolkit provides enterprise-grade performance monitoring and troubleshooting automation:

- **Automated Diagnostics**: Run comprehensive system analysis across multiple servers
- **Real-time Monitoring**: Continuous performance metrics collection
- **Root Cause Analysis**: Identify bottlenecks systematically
- **Remediation**: Auto-fix common performance issues
- **Reporting**: Generate detailed performance reports

## Directory Structure

```
Performance-Troubleshooting/
├── playbooks/
│   ├── performance-check.yml          # Comprehensive health check
│   ├── cpu-troubleshooting.yml        # CPU bottleneck diagnosis
│   ├── memory-troubleshooting.yml     # Memory issue diagnosis
│   ├── disk-troubleshooting.yml       # Disk space and I/O analysis
│   ├── database-troubleshooting.yml   # MySQL/Database performance
│   ├── network-troubleshooting.yml    # Network performance
│   ├── app-performance.yml            # Application-level checks
│   └── auto-remediation.yml           # Auto-fix common issues
├── scripts/
│   ├── performance-diagnostic.sh      # Standalone diagnostic script
│   ├── memory-analyzer.sh             # Memory leak detection
│   ├── disk-io-analyzer.sh            # I/O performance analysis
│   ├── database-analyzer.sh           # Database performance checks
│   └── generate-report.sh             # HTML report generation
├── roles/
│   ├── performance_monitor/           # Monitoring role
│   ├── data_collector/                # Data collection role
│   └── report_generator/              # Report generation role
├── templates/
│   ├── performance-report.j2          # HTML report template
│   └── alert-template.j2              # Alert template
└── inventory/
    └── hosts.yml                      # Ansible inventory

```

## Quick Start

### 1. Run Full Performance Check

```bash
ansible-playbook playbooks/performance-check.yml -i inventory/hosts.yml
```

### 2. Check Specific Issues

```bash
# CPU bottleneck
ansible-playbook playbooks/cpu-troubleshooting.yml -i inventory/hosts.yml

# Memory issues
ansible-playbook playbooks/memory-troubleshooting.yml -i inventory/hosts.yml

# Disk problems
ansible-playbook playbooks/disk-troubleshooting.yml -i inventory/hosts.yml

# Database performance
ansible-playbook playbooks/database-troubleshooting.yml -i inventory/hosts.yml
```

### 3. Run Standalone Script

```bash
bash scripts/performance-diagnostic.sh
```

## Key Features

### ✓ Automated Diagnostics
- System load analysis
- CPU and memory profiling
- Disk space and I/O monitoring
- Network performance analysis
- Database query analysis
- Application-level checks

### ✓ Real-time Monitoring
- Continuous metrics collection
- Trend analysis
- Anomaly detection
- Alert generation

### ✓ Root Cause Analysis
- Bottleneck identification
- Process-level investigation
- System call tracing
- Log analysis

### ✓ Auto-Remediation
- Service restart
- Log rotation
- Cache clearing
- Connection cleanup

### ✓ Detailed Reporting
- HTML reports with charts
- Performance metrics export
- Comparison reports
- Historical trending

## Prerequisites

- Ansible 2.9+
- Python 3.6+
- SSH access to managed nodes
- sudo privileges
- Required packages: sysstat, net-tools, mysql-client (optional)

## Installation

```bash
# 1. Clone the repository
git clone <repo-url>
cd Performance-Troubleshooting

# 2. Install Ansible
pip install ansible>=2.9

# 3. Install required packages on remote servers
ansible-playbook playbooks/setup.yml -i inventory/hosts.yml

# 4. Verify installation
ansible-playbook playbooks/performance-check.yml -i inventory/hosts.yml
```

## Usage Examples

### Run on Single Server

```bash
ansible-playbook playbooks/performance-check.yml -i inventory/hosts.yml --limit web1
```

### Run on Multiple Servers

```bash
ansible-playbook playbooks/performance-check.yml -i inventory/hosts.yml --limit web*
```

### Generate Report

```bash
ansible-playbook playbooks/performance-check.yml -i inventory/hosts.yml -e "generate_report=true"
```

### Auto-fix Issues

```bash
ansible-playbook playbooks/auto-remediation.yml -i inventory/hosts.yml
```

## Output

All results are saved to:
- `/tmp/performance-check-<timestamp>.json` (machine-readable)
- `/tmp/performance-report-<timestamp>.html` (human-readable)
- Ansible logs: `/var/log/ansible/performance-*.log`

## Variables

Customize behavior with variables:

```bash
# Interval for monitoring (seconds)
-e "monitoring_interval=5"

# Duration of monitoring (seconds)
-e "monitoring_duration=60"

# CPU threshold for alerts
-e "cpu_alert_threshold=80"

# Memory threshold for alerts
-e "memory_alert_threshold=85"

# Disk threshold for alerts
-e "disk_alert_threshold=85"
```

## Performance Thresholds

Default thresholds used for alerts:

| Metric | Warning | Critical |
|--------|---------|----------|
| CPU Usage | 75% | 90% |
| Memory Usage | 80% | 95% |
| Disk Usage | 85% | 95% |
| Load Average | cores × 1.5 | cores × 2 |
| I/O Wait | 20% | 40% |
| Disk Await | 50ms | 100ms |

## Troubleshooting

### Playbook fails with "Permission denied"

```bash
# Ensure user has sudo access
ansible-playbook playbooks/performance-check.yml -i inventory/hosts.yml --become
```

### Missing modules error

```bash
# Install required collections
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
```

### Can't connect to remote servers

```bash
# Test connectivity
ansible -i inventory/hosts.yml all -m ping
```

## Advanced Usage

### Custom Playbook

Create your own playbook by combining roles:

```yaml
---
- hosts: all
  vars:
    monitoring_duration: 300
    cpu_alert_threshold: 80
  roles:
    - performance_monitor
    - data_collector
    - report_generator
```

### Continuous Monitoring

Set up a cron job:

```bash
# Run every 5 minutes
*/5 * * * * ansible-playbook /path/to/playbooks/performance-check.yml -i inventory/hosts.yml
```

## Integration

### With Monitoring Systems

- **Prometheus**: Export metrics in Prometheus format
- **Grafana**: Import pre-built dashboards
- **ELK Stack**: Send logs to Elasticsearch
- **Splunk**: Export structured logs

### With Alerting

- **PagerDuty**: Trigger incidents
- **Slack**: Send notifications
- **Email**: Alert recipients

## Performance Impact

This toolkit is designed to have minimal performance impact:

- CPU overhead: < 2%
- Memory overhead: < 50MB
- Disk I/O: < 10MB per run
- Network bandwidth: < 1Mbps

## Limitations

- Requires SSH access to remote servers
- Some checks require root/sudo privileges
- Database checks require MySQL/PostgreSQL client installed
- Large environments (100+ servers) may take longer to run

## Contributing

To add custom checks:

1. Create a new task in `playbooks/` or `roles/`
2. Follow the naming convention
3. Add documentation
4. Test on multiple systems
5. Submit pull request

## Support

For issues or questions:
- Check the troubleshooting section
- Review existing issues
- Create a new issue with detailed information

## License

MIT License - See LICENSE file

## Author

Linux Infrastructure Team

---

**Last Updated**: May 2024
**Version**: 2.0
