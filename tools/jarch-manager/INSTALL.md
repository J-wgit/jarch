# Arch Linux System Manager - Installation & Getting Started

## Quick Start Guide

### Installation (3 Steps)

#### Step 1: Download the Script
```bash
# Make sure you have the arch-manager.sh file
# If downloaded, make it executable:
chmod +x arch-manager.sh
```

#### Step 2: Install System-Wide (Recommended)
```bash
# Install to /usr/local/bin for easy access
sudo install -m 755 arch-manager.sh /usr/local/bin/arch-manager

# Verify installation
which arch-manager
arch-manager version
```

#### Step 3: First Run
```bash
# Launch interactive menu
arch-manager

# Or run a specific command
arch-manager sysinfo
```

### Alternative: Run from Current Directory
```bash
# If you don't want to install system-wide
./arch-manager.sh
```

## First-Time Setup

### 1. Check System Health
```bash
# Get an overview of your system
arch-manager sysinfo

# Check for any failed services
arch-manager check-failed

# View disk usage
arch-manager resources
```

### 2. Create Your First Backup
```bash
# Backup your package list (safe to run)
arch-manager backup-packages

# Optionally backup configs (requires sudo)
sudo arch-manager backup-config
```

### 3. Clean Up (Optional)
```bash
# Check for orphaned packages
sudo arch-manager orphans

# Clean old package cache
sudo arch-manager clean-cache
```

## Usage Examples

### Interactive Mode (Recommended for Beginners)
```bash
# Launch the menu
arch-manager

# Navigate using numbers:
# 1 for system update
# 9 for clean cache
# 16 for system info
# 0 to exit
```

### Command Line Mode (For Experienced Users)
```bash
# Update system
sudo arch-manager update

# Install package
sudo arch-manager install firefox

# Search packages
arch-manager search browser

# Clean cache
sudo arch-manager clean-cache

# System info
arch-manager sysinfo

# Generate report
arch-manager report
```

## Common Tasks

### Daily Use
```bash
# Morning routine
arch-manager check-updates     # Check for updates
arch-manager check-failed      # Check system health
```

### Weekly Maintenance
```bash
# Update system
sudo arch-manager update

# Remove orphans
sudo arch-manager orphans

# Clean cache
sudo arch-manager clean-cache
```

### Monthly Tasks
```bash
# Backup package list
arch-manager backup-packages

# Clean old logs
sudo arch-manager clean-logs

# Generate system report
arch-manager report
```

### Before Installing New Software
```bash
# Search for the package
arch-manager search <package_name>

# Get package info
arch-manager info <package_name>

# Install it
sudo arch-manager install <package_name>
```

### Troubleshooting Boot Problems
```bash
# Analyze boot performance
arch-manager boot-analysis

# Check failed services
arch-manager check-failed

# List kernels
arch-manager list-kernels

# Regenerate initramfs (if needed)
sudo arch-manager regen-initramfs
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
~/.config/arch-manager/          # Configuration
~/system-report-*.txt            # Generated reports
~/boot-analysis-*.svg            # Boot charts
```

### System Files (Requires sudo)
```
/usr/local/bin/arch-manager      # Installed script
/var/backups/arch-manager/       # Backup storage
/var/log/arch-manager/           # Log files
```

## Recommended Workflows

### New Installation Setup
```bash
# 1. Install the script
sudo install -m 755 arch-manager.sh /usr/local/bin/arch-manager

# 2. Update system
sudo arch-manager update

# 3. Clean up
sudo arch-manager orphans
sudo arch-manager clean-cache

# 4. Create baseline backup
arch-manager backup-packages
sudo arch-manager backup-config

# 5. Check system health
arch-manager sysinfo
arch-manager check-failed
```

### Pre-Update Checklist
```bash
# 1. Backup current state
arch-manager backup-packages

# 2. Check system health
arch-manager check-failed

# 3. Update
sudo arch-manager update

# 4. Verify boot
arch-manager boot-analysis
```

### Weekly Maintenance Routine
```bash
# 1. Check for updates
arch-manager check-updates

# 2. Update system
sudo arch-manager update

# 3. Clean orphans
sudo arch-manager orphans

# 4. Check system health
arch-manager check-failed
arch-manager resources
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
0 2 * * 0 /usr/local/bin/arch-manager clean-cache
0 2 * * 0 /usr/local/bin/arch-manager orphans

# Add monthly backup (1st of month)
0 3 1 * * /usr/local/bin/arch-manager backup-packages
```

## Useful Aliases

Add these to your `~/.bashrc` for quicker access:
```bash
# Add to ~/.bashrc
alias am='arch-manager'
alias amu='sudo arch-manager update'
alias ami='sudo arch-manager install'
alias amr='sudo arch-manager remove'
alias ams='arch-manager search'
alias amc='sudo arch-manager clean-cache'
alias amsi='arch-manager sysinfo'

# Reload bashrc
source ~/.bashrc

# Now you can use:
am          # Launch menu
amu         # Update system
ami firefox # Install Firefox
```

## Troubleshooting

### "Command not found: arch-manager"
```bash
# Check if installed
which arch-manager

# If not found, install it
sudo install -m 755 arch-manager.sh /usr/local/bin/arch-manager

# Or run from current directory
./arch-manager.sh
```

### "Permission denied"
```bash
# Make script executable
chmod +x arch-manager.sh

# Or use sudo for system operations
sudo arch-manager update
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
bash -n arch-manager.sh

# Run with debugging
bash -x arch-manager.sh
```

## Getting Help

### Built-in Help
```bash
# Show help
arch-manager help

# Show version
arch-manager version

# Launch interactive menu
arch-manager menu
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

1. **Explore the interactive menu** - Launch `arch-manager` and browse options
2. **Create your first backup** - Run `arch-manager backup-packages`
3. **Check system health** - Run `arch-manager check-failed`
4. **Set up automation** - See `AUTOMATION_EXAMPLES.md`
5. **Create aliases** - Add shortcuts to your `.bashrc`
6. **Read the docs** - Review `README.md` and `QUICK_REFERENCE.md`

## Quick Command Summary

```bash
# Essential commands
arch-manager                    # Interactive menu
arch-manager help              # Show help
arch-manager sysinfo           # System info
sudo arch-manager update       # Update system
arch-manager check-failed      # Check health
arch-manager backup-packages   # Backup packages
arch-manager report            # Generate report

# Maintenance
sudo arch-manager orphans      # Clean orphans
sudo arch-manager clean-cache  # Clean cache
sudo arch-manager clean-logs   # Clean logs

# Package management
arch-manager search <term>     # Search packages
sudo arch-manager install <pkg> # Install package
arch-manager info <pkg>        # Package info

# Monitoring
arch-manager resources         # Resource usage
arch-manager boot-analysis     # Boot performance
arch-manager network           # Network status
```

## Updates and Maintenance

### Updating the Script
```bash
# Download new version
curl -O https://[url]/arch-manager.sh

# Backup old version
sudo cp /usr/local/bin/arch-manager /usr/local/bin/arch-manager.backup

# Install new version
sudo install -m 755 arch-manager.sh /usr/local/bin/arch-manager

# Verify
arch-manager version
```

### Uninstalling
```bash
# Remove script
sudo rm /usr/local/bin/arch-manager

# Remove backups (optional)
rm -rf /var/backups/arch-manager

# Remove config (optional)
rm -rf ~/.config/arch-manager
```

---

**You're all set!** Launch `arch-manager` to get started, or run `arch-manager help` for more information.

For detailed documentation, see:
- **README.md** - Complete feature documentation
- **QUICK_REFERENCE.md** - Command cheatsheet
- **AUTOMATION_EXAMPLES.md** - Systemd timer examples
