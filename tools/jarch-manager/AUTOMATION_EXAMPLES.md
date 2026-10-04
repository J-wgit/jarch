# Systemd Automation Examples for Arch Manager

## Weekly Maintenance Timer

### File: /etc/systemd/system/arch-maintenance.timer
```ini
[Unit]
Description=Weekly Arch Linux System Maintenance
Documentation=man:arch-manager(1)

[Timer]
# Run every Sunday at 2:00 AM
OnCalendar=Sun *-*-* 02:00:00
# Run on boot if missed
Persistent=true
# Randomize start time by up to 1 hour
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

### File: /etc/systemd/system/arch-maintenance.service
```ini
[Unit]
Description=Arch Linux System Maintenance
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
# Run as root
User=root
# Clean package cache (keep 3 versions)
ExecStart=/usr/local/bin/arch-manager clean-cache
# Remove orphaned packages
ExecStart=/usr/local/bin/arch-manager orphans
# Clean old temporary files
ExecStart=/usr/local/bin/arch-manager clean-temp
# Send notification on completion
ExecStartPost=/usr/bin/systemd-cat -t arch-maintenance echo "Maintenance completed"

# Resource limits
Nice=19
IOSchedulingClass=idle
CPUQuota=30%

[Install]
WantedBy=multi-user.target
```

## Daily Update Check

### File: /etc/systemd/system/arch-updatecheck.timer
```ini
[Unit]
Description=Daily Arch Linux Update Check

[Timer]
# Run every day at 9:00 AM
OnCalendar=*-*-* 09:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### File: /etc/systemd/system/arch-updatecheck.service
```ini
[Unit]
Description=Check for Arch Linux Updates
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/arch-manager check-updates
StandardOutput=journal
StandardError=journal
```

## Monthly Package Backup

### File: /etc/systemd/system/arch-backup.timer
```ini
[Unit]
Description=Monthly Arch Linux Package List Backup

[Timer]
# Run on the 1st of each month at 3:00 AM
OnCalendar=*-*-01 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### File: /etc/systemd/system/arch-backup.service
```ini
[Unit]
Description=Backup Arch Linux Package Lists and Configurations

[Service]
Type=oneshot
User=root
# Backup package lists
ExecStart=/usr/local/bin/arch-manager backup-packages
# Backup configuration files
ExecStart=/usr/local/bin/arch-manager backup-config
# Generate system report
ExecStart=/usr/local/bin/arch-manager report

# Cleanup old backups (keep last 6 months)
ExecStartPost=/usr/bin/find /var/backups/arch-manager -type f -mtime +180 -delete
```

## Log Rotation

### File: /etc/systemd/system/arch-logclean.timer
```ini
[Unit]
Description=Monthly System Log Cleanup

[Timer]
# Run monthly
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
```

### File: /etc/systemd/system/arch-logclean.service
```ini
[Unit]
Description=Clean Old System Logs

[Service]
Type=oneshot
User=root
# Keep only last 30 days of logs
ExecStart=/usr/bin/journalctl --vacuum-time=30d
# Or limit to 500M
# ExecStart=/usr/bin/journalctl --vacuum-size=500M
```

## Installation Instructions

### Install All Timers
```bash
# Copy timer and service files to systemd directory
sudo cp arch-maintenance.timer /etc/systemd/system/
sudo cp arch-maintenance.service /etc/systemd/system/
sudo cp arch-updatecheck.timer /etc/systemd/system/
sudo cp arch-updatecheck.service /etc/systemd/system/
sudo cp arch-backup.timer /etc/systemd/system/
sudo cp arch-backup.service /etc/systemd/system/
sudo cp arch-logclean.timer /etc/systemd/system/
sudo cp arch-logclean.service /etc/systemd/system/

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable timers (they will start on boot)
sudo systemctl enable arch-maintenance.timer
sudo systemctl enable arch-updatecheck.timer
sudo systemctl enable arch-backup.timer
sudo systemctl enable arch-logclean.timer

# Start timers immediately
sudo systemctl start arch-maintenance.timer
sudo systemctl start arch-updatecheck.timer
sudo systemctl start arch-backup.timer
sudo systemctl start arch-logclean.timer

# Check timer status
sudo systemctl list-timers
```

### Verify Timers
```bash
# List all active timers
systemctl list-timers --all

# Check specific timer status
systemctl status arch-maintenance.timer

# View timer logs
journalctl -u arch-maintenance.service

# See when timer will run next
systemctl list-timers arch-maintenance.timer
```

### Manual Trigger
```bash
# Manually trigger a service without waiting for timer
sudo systemctl start arch-maintenance.service

# View the output
journalctl -u arch-maintenance.service -f
```

## Cron Alternative

If you prefer cron over systemd timers:

### File: /etc/cron.d/arch-manager
```bash
# Weekly maintenance (Sunday 2 AM)
0 2 * * 0 root /usr/local/bin/arch-manager clean-cache >/dev/null 2>&1
0 2 * * 0 root /usr/local/bin/arch-manager orphans >/dev/null 2>&1

# Daily update check (9 AM)
0 9 * * * root /usr/local/bin/arch-manager check-updates | logger -t arch-updatecheck

# Monthly backup (1st of month, 3 AM)
0 3 1 * * root /usr/local/bin/arch-manager backup-packages >/dev/null 2>&1
0 3 1 * * root /usr/local/bin/arch-manager backup-config >/dev/null 2>&1

# Monthly log cleanup (1st of month, 4 AM)
0 4 1 * * root /usr/bin/journalctl --vacuum-time=30d >/dev/null 2>&1
```

### Install Cron Jobs
```bash
# Copy to cron.d directory
sudo cp arch-manager /etc/cron.d/

# Verify syntax
sudo crontab -l
```

## Email Notifications

### Configure for Email Alerts

Add to service files:
```ini
[Service]
# ... existing configuration ...

# Send email on failure
OnFailure=status-email@%n.service

# Or use a notification script
ExecStartPost=/usr/local/bin/send-notification.sh "Maintenance completed"
```

### Example Notification Script: /usr/local/bin/send-notification.sh
```bash
#!/bin/bash
MESSAGE="$1"
# Using mail command
echo "$MESSAGE" | mail -s "Arch Manager Notification" user@example.com

# Or using notify-send for desktop notifications
# sudo -u username DISPLAY=:0 notify-send "Arch Manager" "$MESSAGE"
```

## Advanced Configuration

### Run Maintenance Before Shutdown

#### File: /etc/systemd/system/arch-shutdown-maintenance.service
```ini
[Unit]
Description=Pre-Shutdown System Maintenance
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/arch-manager clean-temp
ExecStart=/usr/bin/sync
TimeoutStartSec=60

[Install]
WantedBy=halt.target reboot.target shutdown.target
```

### Conditional Execution

Only run if disk usage is high:

```ini
[Service]
Type=oneshot
# Check if /var is over 80% full
ExecCondition=/bin/bash -c 'df /var | awk "NR==2 {exit ($5+0<80)}"'
ExecStart=/usr/local/bin/arch-manager clean-cache
```

## Monitoring Timer Execution

### View Timer Logs
```bash
# All timer activity
journalctl -u "arch-*.timer"

# Specific service execution
journalctl -u arch-maintenance.service -n 50

# Follow logs in real-time
journalctl -u arch-maintenance.service -f

# View failed executions
journalctl -u arch-maintenance.service -p err
```

### Check Last Execution
```bash
# Using systemctl
systemctl status arch-maintenance.timer

# Using journalctl
journalctl -u arch-maintenance.service --since "1 week ago"
```

## Troubleshooting

### Timer Not Running
```bash
# Check if enabled
systemctl is-enabled arch-maintenance.timer

# Check for errors
systemctl status arch-maintenance.timer
journalctl -xe

# Verify timer list
systemctl list-timers --all | grep arch
```

### Service Fails
```bash
# Check service status
systemctl status arch-maintenance.service

# View full logs
journalctl -u arch-maintenance.service -b

# Test service manually
sudo systemctl start arch-maintenance.service
```

### Debug Mode
Add to service file:
```ini
[Service]
# Enable debug output
Environment="SYSTEMD_LOG_LEVEL=debug"
StandardOutput=journal+console
StandardError=journal+console
```

## Best Practices

1. **Test services manually** before enabling timers
2. **Monitor logs** regularly for the first few weeks
3. **Set resource limits** to prevent system impact
4. **Use RandomizedDelaySec** to avoid load spikes
5. **Keep backup retention** policies reasonable
6. **Document customizations** in service descriptions
7. **Review timer schedules** periodically

## Useful Timer Calendar Examples

```ini
# Every 15 minutes
OnCalendar=*:0/15

# Every hour
OnCalendar=hourly

# Every day at 2:30 AM
OnCalendar=*-*-* 02:30:00

# Every Monday at 5:00 PM
OnCalendar=Mon *-*-* 17:00:00

# First day of month at 3 AM
OnCalendar=*-*-01 03:00:00

# Every 6 hours
OnCalendar=0/6:00:00

# Weekdays at 9 AM
OnCalendar=Mon..Fri 09:00:00
```

## Disable/Remove Timers

```bash
# Stop timer
sudo systemctl stop arch-maintenance.timer

# Disable timer
sudo systemctl disable arch-maintenance.timer

# Remove timer files
sudo rm /etc/systemd/system/arch-maintenance.{timer,service}

# Reload systemd
sudo systemctl daemon-reload
```

---

These automation examples will help keep your Arch Linux system maintained automatically!
