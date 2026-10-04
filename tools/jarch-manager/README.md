# Arch Linux System Manager

A comprehensive bash script for managing and maintaining Arch Linux systems with an intuitive menu-driven interface and powerful command-line tools.

## Features

### 📦 Package Management
- Update system packages with one command
- Install and remove packages easily
- Search package repositories
- View detailed package information
- Identify and remove orphaned packages
- List explicitly installed packages
- AUR helper detection and support

### 🔧 System Maintenance
- Clean package cache (with multiple options)
- Manage system logs and journal size
- Detect and investigate failed services
- Filesystem health checking
- Automatic temporary file cleanup
- Orphan package detection and removal

### ⚙️ Service Management
- List services by state (running, enabled, disabled, failed)
- Start, stop, restart services
- Enable and disable services
- View detailed service status

### 📊 System Monitoring
- Comprehensive system information display
- Boot performance analysis with systemd-analyze
- Real-time resource usage monitoring
- Network status and configuration
- Hardware detection and reporting

### 💾 Backup & Restore
- Backup package lists (official and AUR separately)
- Backup critical system configuration files
- Restore packages from previous backups
- Timestamped backup files for version control

### 🔍 Diagnostics
- Generate comprehensive system reports
- Check for available updates
- Analyze boot performance
- Identify system issues automatically

### 🐧 Kernel Management
- List installed kernels
- Display current running kernel
- Regenerate initramfs for all kernels
- Boot configuration overview

### 👥 User Management
- List system users
- Show user group memberships
- User and system account separation

## Installation

### Quick Install

```bash
# Download the script
curl -O https://raw.githubusercontent.com/yourusername/arch-manager/main/arch-manager.sh

# Make it executable
chmod +x arch-manager.sh

# Move to system path (optional)
sudo mv arch-manager.sh /usr/local/bin/arch-manager
```

### Manual Install

1. Clone or download the script
2. Make it executable: `chmod +x arch-manager.sh`
3. Run it: `./arch-manager.sh`

### System-Wide Installation

```bash
# Install to /usr/local/bin for system-wide access
sudo install -m 755 arch-manager.sh /usr/local/bin/arch-manager

# Now you can run it from anywhere
arch-manager
```

## Usage

### Interactive Menu Mode

Simply run the script without arguments to launch the interactive menu:

```bash
./arch-manager.sh
# or if installed system-wide:
arch-manager
```

Navigate through the menu using numbers and follow the prompts.

### Command Line Mode

Run specific commands directly:

```bash
# Update system
arch-manager update

# Install a package
arch-manager install firefox

# Remove a package
arch-manager remove chromium

# Search for packages
arch-manager search nvidia

# Show system information
arch-manager sysinfo

# Clean package cache
arch-manager clean-cache

# Generate system report
arch-manager report

# Backup package list
arch-manager backup-packages

# Check for updates
arch-manager check-updates

# Analyze boot performance
arch-manager boot-analysis

# List installed kernels
arch-manager list-kernels
```

## Command Reference

### Package Management Commands

| Command | Description | Example |
|---------|-------------|---------|
| `update` | Update all system packages | `arch-manager update` |
| `install <pkg>` | Install a package | `arch-manager install vim` |
| `remove <pkg>` | Remove a package and dependencies | `arch-manager remove firefox` |
| `search <term>` | Search for packages | `arch-manager search browser` |
| `info <pkg>` | Show package details | `arch-manager info linux` |
| `orphans` | List and remove orphaned packages | `arch-manager orphans` |
| `explicit` | List explicitly installed packages | `arch-manager explicit` |

### System Maintenance Commands

| Command | Description | Example |
|---------|-------------|---------|
| `clean-cache` | Clean pacman package cache | `arch-manager clean-cache` |
| `clean-logs` | Clean systemd journal logs | `arch-manager clean-logs` |
| `check-failed` | Check for failed services | `arch-manager check-failed` |
| `check-fs` | Check filesystem health | `arch-manager check-fs` |
| `clean-temp` | Clean temporary files | `arch-manager clean-temp` |

### Monitoring Commands

| Command | Description | Example |
|---------|-------------|---------|
| `sysinfo` | Display system information | `arch-manager sysinfo` |
| `boot-analysis` | Analyze boot performance | `arch-manager boot-analysis` |
| `resources` | Show CPU, memory, disk usage | `arch-manager resources` |
| `network` | Show network configuration | `arch-manager network` |

### Backup Commands

| Command | Description | Example |
|---------|-------------|---------|
| `backup-packages` | Backup installed package list | `arch-manager backup-packages` |
| `backup-config` | Backup system config files | `arch-manager backup-config` |
| `restore-packages` | Restore from package backup | `arch-manager restore-packages` |

### Kernel Commands

| Command | Description | Example |
|---------|-------------|---------|
| `list-kernels` | List installed kernels | `arch-manager list-kernels` |
| `regen-initramfs` | Regenerate initramfs images | `arch-manager regen-initramfs` |

### Diagnostic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `report` | Generate full system diagnostic report | `arch-manager report` |
| `check-updates` | Check for available updates | `arch-manager check-updates` |

## Features in Detail

### Package Cache Management

The cache cleaner offers multiple options:
1. **Keep 3 most recent versions** - Recommended for most users
2. **Remove uninstalled packages** - Frees space while keeping installed package cache
3. **Remove all cached packages** - Complete cleanup (use with caution)

### Log Management

Choose how to manage your systemd journal:
- Keep logs from last 7 or 30 days
- Limit total log size (e.g., 500MB)
- Vacuum old logs with timestamp-based cleanup

### System Reports

The diagnostic report includes:
- Complete system information
- Kernel parameters
- Boot analysis
- Failed services
- Disk usage
- Memory information
- Package statistics
- Recent error logs
- Network configuration

Reports are saved with timestamps for tracking system changes over time.

### Boot Analysis

Provides detailed boot performance metrics:
- Total boot time breakdown
- Service startup times
- Critical path analysis
- Optional SVG chart generation

### Backup System

Backups are stored in `/var/backups/arch-manager/` with timestamps:
- `packages-YYYYMMDD-HHMMSS.txt` - Official packages
- `packages-aur-YYYYMMDD-HHMMSS.txt` - AUR packages
- `config-backup-YYYYMMDD-HHMMSS.tar.gz` - System configs

## Requirements

### Essential
- Arch Linux (or Arch-based distribution)
- Bash 4.0 or higher
- sudo privileges (for system modifications)

### Recommended Packages
```bash
sudo pacman -S \
    pacman-contrib \    # For paccache
    systemd \           # For systemctl, journalctl
    iproute2 \          # For ip command
    util-linux \        # For various utilities
    procps-ng           # For ps, free, etc.
```

### Optional (for full functionality)
```bash
# For AUR support
yay -S yay
# or
paru -S paru

# For advanced monitoring
sudo pacman -S sysstat lsof htop
```

## Configuration

The script creates configuration directories on first run:
- `/var/log/arch-manager/` - Log files (requires sudo)
- `~/.config/arch-manager/` - User configuration
- `/var/backups/arch-manager/` - Backup storage

## Safety Features

- **Confirmation prompts** for destructive operations
- **Root privilege checks** for system modifications
- **Dry-run information** before major changes
- **Backup recommendations** before critical operations
- **Error handling** with clear messages

## Tips & Best Practices

### Regular Maintenance

Create a weekly maintenance routine:
```bash
# Check for updates
arch-manager check-updates

# Update system
sudo arch-manager update

# Clean orphaned packages
sudo arch-manager orphans

# Clean old logs (monthly)
sudo arch-manager clean-logs

# Backup package list (before major changes)
arch-manager backup-packages
```

### Before System Updates

```bash
# 1. Backup package list
arch-manager backup-packages

# 2. Backup configurations
sudo arch-manager backup-config

# 3. Check for failed services
arch-manager check-failed

# 4. Update system
sudo arch-manager update
```

### After Installing New Software

```bash
# Check for orphaned packages
sudo arch-manager orphans

# Verify no services failed
arch-manager check-failed
```

### Performance Optimization

```bash
# Analyze boot time
arch-manager boot-analysis

# Check resource usage
arch-manager resources

# Review enabled services
arch-manager menu  # Then option 14
```

## Troubleshooting

### Permission Denied Errors
Some operations require root privileges. Use `sudo`:
```bash
sudo arch-manager update
sudo arch-manager clean-cache
```

### Cache Cleaning Fails
Ensure `pacman-contrib` is installed:
```bash
sudo pacman -S pacman-contrib
```

### Boot Analysis Shows "Command Not Found"
This is normal on some minimal installations. Install systemd if missing.

### Backup Directory Not Accessible
The script will create necessary directories. Ensure you have write permissions to your home directory.

## Advanced Usage

### Automation with Cron

Create automated maintenance tasks:

```bash
# Edit crontab
crontab -e

# Add weekly cleanup (Sundays at 2 AM)
0 2 * * 0 /usr/local/bin/arch-manager clean-cache
0 2 * * 0 /usr/local/bin/arch-manager clean-logs

# Add monthly package list backup
0 3 1 * * /usr/local/bin/arch-manager backup-packages
```

### Integration with System Services

Create a systemd timer for regular maintenance:

```bash
# /etc/systemd/system/arch-maintenance.timer
[Unit]
Description=Weekly Arch Linux Maintenance

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
# /etc/systemd/system/arch-maintenance.service
[Unit]
Description=Arch Linux Maintenance Tasks

[Service]
Type=oneshot
ExecStart=/usr/local/bin/arch-manager clean-cache
ExecStart=/usr/local/bin/arch-manager orphans
```

Enable the timer:
```bash
sudo systemctl enable --now arch-maintenance.timer
```

## Security Considerations

- Always review package lists before restoring
- Verify backup integrity before relying on them
- Be cautious with cache cleaning options
- Keep sudo sessions minimal
- Review generated reports before sharing (may contain sensitive info)

## Contributing

Contributions are welcome! Areas for improvement:
- Additional maintenance tasks
- More backup options
- Enhanced monitoring features
- Better error handling
- Automated testing

## License

This script is provided as-is for managing Arch Linux systems. Use at your own risk.

## Changelog

### Version 1.0.0
- Initial release
- Complete package management suite
- System maintenance tools
- Service management
- Monitoring and diagnostics
- Backup and restore functionality
- Kernel management
- User management
- Interactive menu interface
- Command-line interface

## FAQ

**Q: Is this safe to use on my daily driver?**
A: Yes, the script includes safety checks and confirmations for destructive operations.

**Q: Can I use this on Manjaro or other Arch-based distros?**
A: Yes, it should work on most Arch-based distributions.

**Q: Do I need to run everything as root?**
A: No, only system-modifying operations require root privileges.

**Q: How often should I clean package cache?**
A: Monthly or when disk space is low. The "keep 3 versions" option is safest.

**Q: Will this work with AUR helpers?**
A: Yes, it detects yay and paru and can work alongside them.

**Q: Can I customize the menu?**
A: Yes, the script is open source - edit it to add your own functions!

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check the Arch Wiki
- Consult the Arch Linux forums

## Acknowledgments

- Arch Linux community for excellent documentation
- systemd developers for comprehensive system management tools
- Contributors to pacman and related utilities
