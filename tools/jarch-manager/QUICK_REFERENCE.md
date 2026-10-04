# Arch Manager Quick Reference Card

## Daily Operations

```bash
# Check system status
arch-manager sysinfo

# Check for updates
arch-manager check-updates

# Update system
sudo arch-manager update

# Check failed services
arch-manager check-failed
```

## Weekly Maintenance

```bash
# Clean orphaned packages
sudo arch-manager orphans

# Clean package cache (keep 3 versions)
sudo arch-manager clean-cache

# Check disk space
arch-manager resources
```

## Monthly Tasks

```bash
# Backup package list
arch-manager backup-packages

# Backup configurations
sudo arch-manager backup-config

# Clean old logs
sudo arch-manager clean-logs

# Generate system report
arch-manager report
```

## Common Workflows

### Installing New Software
```bash
# Search for package
arch-manager search <package_name>

# View package info
arch-manager info <package_name>

# Install package
sudo arch-manager install <package_name>

# Check for orphans afterwards
sudo arch-manager orphans
```

### Troubleshooting Boot Issues
```bash
# Analyze boot performance
arch-manager boot-analysis

# Check failed services
arch-manager check-failed

# List installed kernels
arch-manager list-kernels

# Regenerate initramfs if needed
sudo arch-manager regen-initramfs
```

### Before Major Updates
```bash
# 1. Backup current state
arch-manager backup-packages
sudo arch-manager backup-config

# 2. Check system health
arch-manager check-failed
arch-manager check-fs

# 3. Clean system
sudo arch-manager orphans
sudo arch-manager clean-cache

# 4. Update
sudo arch-manager update
```

### System Cleanup
```bash
# Remove orphaned packages
sudo arch-manager orphans

# Clean package cache
sudo arch-manager clean-cache

# Clean temporary files
sudo arch-manager clean-temp

# Clean old logs
sudo arch-manager clean-logs
```

### Service Management
```bash
# List all services
arch-manager menu  # Option 14

# Check failed services
arch-manager check-failed

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
arch-manager sysinfo

# Resource usage
arch-manager resources

# Network status
arch-manager network

# Boot analysis
arch-manager boot-analysis

# Full diagnostic report
arch-manager report
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
arch-manager check-failed

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
Configuration:
~/.config/arch-manager/config

Logs:
/var/log/arch-manager/

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

💡 **Tip**: Run `arch-manager menu` for interactive mode
💡 **Tip**: Use tab completion for command names
💡 **Tip**: Add `arch-manager` to your PATH for easier access
💡 **Tip**: Create aliases for frequently used commands
💡 **Tip**: Schedule regular backups with cron
💡 **Tip**: Review reports before sharing (may contain sensitive data)

## Useful Aliases

Add to your `~/.bashrc`:

```bash
# Arch Manager shortcuts
alias am='arch-manager'
alias amu='sudo arch-manager update'
alias ami='sudo arch-manager install'
alias amr='sudo arch-manager remove'
alias ams='arch-manager search'
alias amc='sudo arch-manager clean-cache'
alias amb='arch-manager backup-packages'
alias amsi='arch-manager sysinfo'
```

## Common Error Solutions

### "Command not found: paccache"
```bash
sudo pacman -S pacman-contrib
```

### "Permission denied"
```bash
# Add sudo for system operations
sudo arch-manager <command>
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
arch-manager help

# Show version
arch-manager version

# Interactive menu
arch-manager menu
arch-manager  # (same as menu)
```

---

**Remember**: Always backup before major changes!

Print this guide or save it for quick reference during system maintenance.
