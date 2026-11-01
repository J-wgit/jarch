# Jarch Manager - Installation & Getting Started

## Quick Start Guide

### Installation

On Jarch, `jarch-manager` is already installed from the `[jarch]` pacman repo
and updated by `pacman -Syu`. Elsewhere, see **Installation** in README.md.

```bash
which jarch-manager
jarch-manager version
jarch-manager            # interactive menu
jarch-manager sysinfo    # or a single command
```

## First-Time Setup

### 1. Check System Health
```bash
# Get an overview of your system
jarch-manager sysinfo

# Check for any failed services
jarch-manager check-failed

# View disk usage
jarch-manager resources
```

### 2. Create Your First Backup
```bash
# Backup your package list (safe to run)
jarch-manager backup-packages

# Optionally backup configs (requires sudo)
jarch-manager backup-config
```

### 3. Clean Up (Optional)
```bash
# Check for orphaned packages
jarch-manager orphans

# Clean old package cache
jarch-manager clean-cache
```

## Usage Examples

### Interactive Mode (Recommended for Beginners)
```bash
# Launch the menu
jarch-manager

# Navigate using numbers:
# 1 for system update
# 9 for clean cache
# 16 for system info
# 0 to exit
```

### Command Line Mode (For Experienced Users)
```bash
# Update system
jarch-manager update

# Install package
jarch-manager install firefox

# Search packages
jarch-manager search browser

# Clean cache
jarch-manager clean-cache

# System info
jarch-manager sysinfo

# Generate report
jarch-manager report
```

## Common Tasks

### Daily Use
```bash
# Morning routine
jarch-manager check-updates     # Check for updates
jarch-manager check-failed      # Check system health
```

### Weekly Maintenance
```bash
# Update system
jarch-manager update

# Remove orphans
jarch-manager orphans

# Clean cache
jarch-manager clean-cache
```

### Monthly Tasks
```bash
# Backup package list
jarch-manager backup-packages

# Clean old logs
jarch-manager clean-logs

# Generate system report
jarch-manager report
```

### Before Installing New Software
```bash
# Search for the package
jarch-manager search <package_name>

# Get package info
jarch-manager info <package_name>

# Install it
jarch-manager install <package_name>
```

### Troubleshooting Boot Problems
```bash
# Analyze boot performance
jarch-manager boot-analysis

# Check failed services
jarch-manager check-failed

# List kernels
jarch-manager list-kernels

# Regenerate initramfs (if needed)
jarch-manager regen-initramfs
```

## Understanding the Menu

### Menu Sections

**Package Management (Options 1-8)**
- System updates
- Install/remove packages
- Search and information
- Manage orphaned packages

**System Maintenance (Options 9-13)**
- Clean cache and logs
- Check system health
- Filesystem checks

**Service Management (Options 14-15)**
- View and manage systemd services
- Check failed services

**Monitoring (Options 16-19)**
- System information
- Performance analysis
- Resource usage
- Network status

**Backup & Restore (Options 20-22)**
- Backup package lists
- Backup configurations
- Restore from backups

**Kernel Management (Options 23-24)**
- View installed kernels
- Manage initramfs

**User Management (Options 25-26)**
- List users and groups

**Diagnostics (Options 27-28)**
- Generate system reports
- Check for updates

## Safety Features

### Confirmations
The script asks for confirmation before:
- Removing packages
- Cleaning all cache
- Removing orphaned packages
- Other destructive operations

### Root Checks
Only operations that modify the system require root privileges.

### Backups
The script encourages regular backups before major changes.

## File Locations

### User Files (No sudo needed)
```
~/.config/jarch-manager/config   # Your settings (see README.md)
~/system-report-*.txt            # Generated reports (REPORT_DIR)
~/boot-analysis-*.svg            # Boot charts (REPORT_DIR)
```

### System Files (Requires sudo)
```
/usr/bin/jarch-manager           # Installed by the jarch-manager package
/etc/jarch-manager.conf          # System-wide settings
/var/backups/arch-manager/       # Backup storage (BACKUP_DIR)
```

## Recommended Workflows

### New Installation Setup
```bash
# 1. Install it (already done on Jarch)
sudo pacman -S jarch-manager

# 2. Update system
jarch-manager update

# 3. Clean up
jarch-manager orphans
jarch-manager clean-cache

# 4. Create baseline backup
jarch-manager backup-packages
jarch-manager backup-config

# 5. Check system health
jarch-manager sysinfo
jarch-manager check-failed
```

### Pre-Update Checklist
```bash
# 1. Backup current state
jarch-manager backup-packages

# 2. Check system health
jarch-manager check-failed

# 3. Update
jarch-manager update

# 4. Verify boot
jarch-manager boot-analysis
```

### Weekly Maintenance Routine
```bash
# 1. Check for updates
jarch-manager check-updates

# 2. Update system
jarch-manager update

# 3. Clean orphans
jarch-manager orphans

# 4. Check system health
jarch-manager check-failed
jarch-manager resources
```

## Automation Setup (Optional)

### Using Systemd Timers (Recommended)
See `AUTOMATION_EXAMPLES.md` for complete timer setups.

Quick setup for weekly maintenance:
```bash
# Create timer (see AUTOMATION_EXAMPLES.md for file contents)
sudo nano /etc/systemd/system/arch-maintenance.timer
sudo nano /etc/systemd/system/arch-maintenance.service

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now arch-maintenance.timer

# Check status
systemctl status arch-maintenance.timer
systemctl list-timers
```

### Using Cron (Alternative)
```bash
# Edit root crontab
sudo crontab -e

# Add weekly maintenance (Sunday 2 AM)
0 2 * * 0 /usr/bin/jarch-manager clean-cache
0 2 * * 0 /usr/bin/jarch-manager orphans

# Add monthly backup (1st of month)
0 3 1 * * /usr/bin/jarch-manager backup-packages
```

## Useful Aliases

Add these to your `~/.bashrc` for quicker access:
```bash
# Add to ~/.bashrc
alias am='jarch-manager'
alias amu='jarch-manager update'
alias ami='jarch-manager install'
alias amr='jarch-manager remove'
alias ams='jarch-manager search'
alias amc='jarch-manager clean-cache'
alias amsi='jarch-manager sysinfo'

# Reload bashrc
source ~/.bashrc

# Now you can use:
am          # Launch menu
amu         # Update system
ami firefox # Install Firefox
```

## Troubleshooting

### "Command not found: jarch-manager"
```bash
# Check if installed
which jarch-manager

# If not found, install it from [jarch]
sudo pacman -S jarch-manager
```

### "Permission denied"
```bash
# jarch-manager uses sudo for system changes: check you're in the wheel group
groups
```

### "Command not found: paccache"
```bash
# Install pacman-contrib
sudo pacman -S pacman-contrib
```

### Script won't run
```bash
# Check bash version (needs 4.0+)
bash --version

# Check script syntax
bash -n /usr/bin/jarch-manager

# Run with debugging
bash -x /usr/bin/jarch-manager
```

## Getting Help

### Built-in Help
```bash
# Show help
jarch-manager help

# Show version
jarch-manager version

# Launch interactive menu
jarch-manager menu
```

### Documentation
- `README.md` - Full documentation
- `QUICK_REFERENCE.md` - Quick command reference
- `AUTOMATION_EXAMPLES.md` - Automation setup guides

### Community Support
- Arch Linux Wiki: https://wiki.archlinux.org
- Arch Linux Forums: https://bbs.archlinux.org
- Man pages: `man pacman`, `man systemctl`, etc.

## Best Practices

### DO:
✅ Backup before major changes
✅ Read update news before updating
✅ Check failed services regularly
✅ Clean cache periodically
✅ Monitor disk usage
✅ Keep package lists backed up

### DON'T:
❌ Remove all cache without understanding implications
❌ Skip reading update announcements
❌ Ignore failed services
❌ Run commands you don't understand
❌ Mix different package managers carelessly

## Next Steps

1. **Explore the interactive menu** - Launch `jarch-manager` and browse options
2. **Create your first backup** - Run `jarch-manager backup-packages`
3. **Check system health** - Run `jarch-manager check-failed`
4. **Set up automation** - See `AUTOMATION_EXAMPLES.md`
5. **Create aliases** - Add shortcuts to your `.bashrc`
6. **Read the docs** - Review `README.md` and `QUICK_REFERENCE.md`

## Quick Command Summary

```bash
# Essential commands
jarch-manager                    # Interactive menu
jarch-manager help              # Show help
jarch-manager sysinfo           # System info
jarch-manager update       # Update system
jarch-manager check-failed      # Check health
jarch-manager backup-packages   # Backup packages
jarch-manager report            # Generate report

# Maintenance
jarch-manager orphans      # Clean orphans
jarch-manager clean-cache  # Clean cache
jarch-manager clean-logs   # Clean logs

# Package management
jarch-manager search <term>     # Search packages
jarch-manager install <pkg> # Install package
jarch-manager info <pkg>        # Package info

# Monitoring
jarch-manager resources         # Resource usage
jarch-manager boot-analysis     # Boot performance
jarch-manager network           # Network status
```

## Updates and Maintenance

### Updating

`jarch-manager` is a pacman package from `[jarch]`, so a normal `pacman -Syu`
(or `jarch-manager update`) updates it.

### Uninstalling
```bash
sudo pacman -Rns jarch-manager

# Remove backups (optional)
sudo rm -rf /var/backups/arch-manager

# Remove config (optional)
rm -rf ~/.config/jarch-manager ~/.config/arch-manager
```

---

**You're all set!** Launch `jarch-manager` to get started, or run `jarch-manager help` for more information.

For detailed documentation, see:
- **README.md** - Complete feature documentation
- **QUICK_REFERENCE.md** - Command cheatsheet
- **AUTOMATION_EXAMPLES.md** - Systemd timer examples
