# Arch Manager Quick Reference Card

## Daily Operations

```bash
# Check system status
jarch-manager sysinfo

# Check for updates
jarch-manager check-updates

# Update system
jarch-manager update

# Check failed services
jarch-manager check-failed
```

## Weekly Maintenance

```bash
# Clean orphaned packages
jarch-manager orphans

# Clean package cache (keep 3 versions)
jarch-manager clean-cache

# Check disk space
jarch-manager resources
```

## Monthly Tasks

```bash
# Backup package list
jarch-manager backup-packages

# Backup configurations
jarch-manager backup-config

# Clean old logs
jarch-manager clean-logs

# Generate system report
jarch-manager report
```

## Common Workflows

### Installing New Software
```bash
# Search for package
jarch-manager search <package_name>

# View package info
jarch-manager info <package_name>

# Install package
jarch-manager install <package_name>

# Check for orphans afterwards
jarch-manager orphans
```

### Troubleshooting Boot Issues
```bash
# Analyze boot performance
jarch-manager boot-analysis

# Check failed services
jarch-manager check-failed

# List installed kernels
jarch-manager list-kernels

# Regenerate initramfs if needed
jarch-manager regen-initramfs
```

### Before Major Updates
```bash
# 1. Backup current state
jarch-manager backup-packages
jarch-manager backup-config

# 2. Check system health
jarch-manager check-failed
jarch-manager check-fs

# 3. Clean system
jarch-manager orphans
jarch-manager clean-cache

# 4. Update
jarch-manager update
```

### System Cleanup
```bash
# Remove orphaned packages
jarch-manager orphans

# Clean package cache
jarch-manager clean-cache

# Clean temporary files
jarch-manager clean-temp

# Clean old logs
jarch-manager clean-logs
```

### Service Management
```bash
# List all services
jarch-manager menu  # Option 14

# Check failed services
jarch-manager check-failed

# Manage specific service
sudo systemctl status <service>
sudo systemctl start <service>
sudo systemctl stop <service>
sudo systemctl restart <service>
sudo systemctl enable <service>
sudo systemctl disable <service>
```

### Monitoring

```bash
# System overview
jarch-manager sysinfo

# Resource usage
jarch-manager resources

# Network status
jarch-manager network

# Boot analysis
jarch-manager boot-analysis

# Full diagnostic report
jarch-manager report
```

## Emergency Recovery

### System Won't Boot
```bash
# Boot from live USB
# Mount root partition
mount /dev/sdXY /mnt

# Mount boot partition (if separate)
mount /dev/sdXZ /mnt/boot

# Chroot into system
arch-chroot /mnt

# Check/regenerate initramfs
mkinitcpio -P

# Check bootloader config
# For GRUB:
grub-mkconfig -o /boot/grub/grub.cfg

# For systemd-boot:
bootctl update
```

### Broken Package Database
```bash
# Restore from backup
sudo pacman -S --needed - < /var/backups/arch-manager/packages-*.txt
```

### Service Failures
```bash
# Check what failed
jarch-manager check-failed

# View service logs
journalctl -xeu <service_name>

# Restart service
sudo systemctl restart <service_name>
```

## Keyboard Shortcuts in Interactive Menu

- **Number + Enter**: Select menu option
- **y/Y**: Confirm action
- **n/N**: Cancel action
- **0**: Exit menu

## File Locations

```
Configuration (later wins; see `jarch-manager config`):
/etc/jarch-manager.conf
~/.config/jarch-manager/config

Backups:
/var/backups/arch-manager/
├── packages-*.txt          # Official packages
├── packages-aur-*.txt      # AUR packages
└── config-backup-*.tar.gz  # System configs

Generated Reports:
~/system-report-*.txt
~/boot-analysis-*.svg
```

## Quick Tips

💡 **Tip**: Run `jarch-manager menu` for interactive mode
💡 **Tip**: Use tab completion for command names
💡 **Tip**: Add `jarch-manager` to your PATH for easier access
💡 **Tip**: Create aliases for frequently used commands
💡 **Tip**: Schedule regular backups with cron
💡 **Tip**: Review reports before sharing (may contain sensitive data)

## Useful Aliases

Add to your `~/.bashrc`:

```bash
# Arch Manager shortcuts
alias am='jarch-manager'
alias amu='jarch-manager update'
alias ami='jarch-manager install'
alias amr='jarch-manager remove'
alias ams='jarch-manager search'
alias amc='jarch-manager clean-cache'
alias amb='jarch-manager backup-packages'
alias amsi='jarch-manager sysinfo'
```

## Common Error Solutions

### "Command not found: paccache"
```bash
sudo pacman -S pacman-contrib
```

### "Permission denied"
```bash
# Add sudo for system operations
jarch-manager <command>
```

### "Journal is not persistent"
```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

### "Failed to get D-Bus connection"
```bash
# Usually safe to ignore in containers/chroot
# Or start D-Bus:
sudo systemctl start dbus
```

## Performance Optimization Commands

```bash
# Find slow boot services
systemd-analyze blame | head -20

# View critical boot path
systemd-analyze critical-chain

# Generate boot timeline
systemd-analyze plot > boot.svg

# Check for errors
journalctl -b -p err

# List enabled services
systemctl list-unit-files --state=enabled
```

## Keyboard Cheatsheet

```
Ctrl+C    = Cancel current operation
Ctrl+D    = Exit (in some prompts)
Ctrl+L    = Clear screen (in menu)
q         = Quit pager (less)
/         = Search in pager
n/p       = Next/Previous in search
```

## Exit Codes

```
0   = Success
1   = General error
130 = Interrupted by Ctrl+C
```

## Getting Help

```bash
# Show help
jarch-manager help

# Show version
jarch-manager version

# Interactive menu
jarch-manager menu
jarch-manager  # (same as menu)
```

---

**Remember**: Always backup before major changes!

Print this guide or save it for quick reference during system maintenance.
