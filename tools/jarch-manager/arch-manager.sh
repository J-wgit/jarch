#!/bin/bash

################################################################################
# Arch Linux System Manager
# A comprehensive script for managing Arch Linux systems
#
# Features:
# - Package management (install, update, clean)
# - System maintenance (logs, cache, orphans)
# - Service management
# - System monitoring and diagnostics
# - Backup and restore
# - Kernel management
# - Boot configuration
# - User management
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script configuration
SCRIPT_VERSION="1.0.0"
LOG_DIR="/var/log/arch-manager"
BACKUP_DIR="/var/backups/arch-manager"
CONFIG_FILE="$HOME/.config/arch-manager/config"

################################################################################
# Utility Functions
################################################################################

print_header() {
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This function requires root privileges"
        echo "Please run with sudo or as root"
        return 1
    fi
}

confirm_action() {
    local message="$1"
    echo -e "${YELLOW}${message}${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
        return 1
    fi
    return 0
}

create_dirs() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
}

# The backup dir lives under /var, so it's created (owned by you) with sudo,
# and only by the commands that write backups
ensure_backup_dir() {
    [[ -w "$BACKUP_DIR" ]] && return 0
    sudo install -d -o "$(id -un)" -g "$(id -gn)" "$BACKUP_DIR"
}

################################################################################
# Package Management Functions
################################################################################

pkg_update_system() {
    print_header "System Update"
    check_root || return 1

    print_info "Syncing package databases..."
    pacman -Sy

    print_info "Checking for updates..."
    local updates=$(pacman -Qu | wc -l)

    if [[ $updates -eq 0 ]]; then
        print_success "System is up to date!"
        return 0
    fi

    echo -e "\n${CYAN}Available updates: ${BOLD}$updates${NC}\n"
    pacman -Qu
    echo

    if confirm_action "Update all packages?"; then
        pacman -Syu --noconfirm
        print_success "System updated successfully!"

        # Check if reboot needed
        if [[ -f /var/run/reboot-required ]]; then
            print_warning "System reboot recommended"
        fi
    fi
}

pkg_install() {
    print_header "Package Installation"
    check_root || return 1

    if [[ -z "$1" ]]; then
        print_error "No package specified"
        echo "Usage: $0 install <package_name>"
        return 1
    fi

    local package="$1"
    print_info "Installing package: $package"
    pacman -S "$package"
    print_success "Package installed successfully!"
}

pkg_remove() {
    print_header "Package Removal"
    check_root || return 1

    if [[ -z "$1" ]]; then
        print_error "No package specified"
        echo "Usage: $0 remove <package_name>"
        return 1
    fi

    local package="$1"
    if confirm_action "Remove package '$package' and its dependencies?"; then
        pacman -Rns "$package"
        print_success "Package removed successfully!"
    fi
}

pkg_search() {
    print_header "Package Search"

    if [[ -z "$1" ]]; then
        print_error "No search term specified"
        echo "Usage: $0 search <search_term>"
        return 1
    fi

    local search_term="$1"
    print_info "Searching for: $search_term"
    pacman -Ss "$search_term"
}

pkg_info() {
    print_header "Package Information"

    if [[ -z "$1" ]]; then
        print_error "No package specified"
        echo "Usage: $0 info <package_name>"
        return 1
    fi

    local package="$1"
    if pacman -Qi "$package" &>/dev/null; then
        pacman -Qi "$package"
    else
        print_warning "Package not installed locally, searching repositories..."
        pacman -Si "$package"
    fi
}

pkg_list_orphans() {
    print_header "Orphaned Packages"

    local orphans=$(pacman -Qtdq 2>/dev/null)

    if [[ -z "$orphans" ]]; then
        print_success "No orphaned packages found!"
        return 0
    fi

    echo -e "${CYAN}Orphaned packages:${NC}"
    echo "$orphans"
    echo

    if confirm_action "Remove all orphaned packages?"; then
        check_root || return 1
        pacman -Rns $(pacman -Qtdq) --noconfirm
        print_success "Orphaned packages removed!"
    fi
}

pkg_list_explicit() {
    print_header "Explicitly Installed Packages"

    local count=$(pacman -Qe | wc -l)
    echo -e "${CYAN}Total explicit packages: ${BOLD}$count${NC}\n"

    pacman -Qe | less
}

pkg_aur_helper_check() {
    print_header "AUR Helper Status"

    if command -v yay &>/dev/null; then
        print_success "yay is installed"
        yay --version
    elif command -v paru &>/dev/null; then
        print_success "paru is installed"
        paru --version
    else
        print_warning "No AUR helper detected"
        echo "Consider installing 'yay' or 'paru' for AUR support"
    fi
}

################################################################################
# System Maintenance Functions
################################################################################

maint_clean_cache() {
    print_header "Package Cache Cleanup"
    check_root || return 1

    print_info "Checking package cache..."
    local cache_size=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
    echo -e "${CYAN}Current cache size: ${BOLD}$cache_size${NC}\n"

    echo "Cleanup options:"
    echo "1) Remove all cached packages except the 3 most recent versions"
    echo "2) Remove all uninstalled packages from cache"
    echo "3) Remove all packages from cache"
    echo "4) Cancel"
    echo
    read -p "Select option (1-4): " -n 1 -r
    echo

    case $REPLY in
        1)
            print_info "Keeping 3 most recent versions..."
            paccache -rk3
            print_success "Cache cleaned!"
            ;;
        2)
            print_info "Removing uninstalled packages..."
            paccache -ruk0
            print_success "Cache cleaned!"
            ;;
        3)
            if confirm_action "Remove ALL packages from cache?"; then
                pacman -Scc --noconfirm
                print_success "Cache completely cleared!"
            fi
            ;;
        4)
            print_info "Operation cancelled"
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac

    local new_size=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
    echo -e "\n${CYAN}New cache size: ${BOLD}$new_size${NC}"
}

maint_clean_logs() {
    print_header "System Log Cleanup"
    check_root || return 1

    print_info "Checking journal size..."
    journalctl --disk-usage
    echo

    echo "Log cleanup options:"
    echo "1) Keep logs from last 7 days"
    echo "2) Keep logs from last 30 days"
    echo "3) Limit total log size to 500M"
    echo "4) Vacuum logs older than 1 week"
    echo "5) Cancel"
    echo
    read -p "Select option (1-5): " -n 1 -r
    echo

    case $REPLY in
        1)
            journalctl --vacuum-time=7d
            print_success "Old logs removed!"
            ;;
        2)
            journalctl --vacuum-time=30d
            print_success "Old logs removed!"
            ;;
        3)
            journalctl --vacuum-size=500M
            print_success "Logs trimmed to size!"
            ;;
        4)
            journalctl --vacuum-time=1weeks
            print_success "Old logs removed!"
            ;;
        5)
            print_info "Operation cancelled"
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac

    echo
    print_info "New journal size:"
    journalctl --disk-usage
}

maint_check_failed() {
    print_header "Failed Services Check"

    local failed=$(systemctl --failed --no-pager --no-legend | wc -l)

    if [[ $failed -eq 0 ]]; then
        print_success "No failed services!"
        return 0
    fi

    print_warning "Found $failed failed service(s):"
    echo
    systemctl --failed --no-pager
    echo

    read -p "View detailed logs for a service? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter service name: " service_name
        journalctl -xeu "$service_name" --no-pager | less
    fi
}

maint_filesystem_check() {
    print_header "Filesystem Health Check"

    print_info "Disk usage:"
    df -h | grep -E "^/dev/|Filesystem"
    echo

    print_info "Checking for filesystem errors in logs..."
    local errors=$(journalctl -b -p err --no-pager | grep -i "filesystem\|ext4\|btrfs\|xfs" | wc -l)

    if [[ $errors -eq 0 ]]; then
        print_success "No filesystem errors found in current boot"
    else
        print_warning "Found $errors filesystem-related error(s)"
        echo "Run 'journalctl -b -p err | grep -i filesystem' for details"
    fi
}

maint_temp_files() {
    print_header "Temporary Files Cleanup"
    check_root || return 1

    print_info "Checking temporary directories..."

    echo -e "\n${CYAN}/tmp size:${NC}"
    du -sh /tmp 2>/dev/null || echo "N/A"

    echo -e "\n${CYAN}/var/tmp size:${NC}"
    du -sh /var/tmp 2>/dev/null || echo "N/A"

    if confirm_action "Clean temporary files older than 7 days?"; then
        find /tmp -type f -atime +7 -delete 2>/dev/null || true
        find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
        print_success "Old temporary files cleaned!"
    fi
}

################################################################################
# Service Management Functions
################################################################################

service_list() {
    print_header "System Services"

    echo "Service status options:"
    echo "1) All running services"
    echo "2) All enabled services"
    echo "3) All disabled services"
    echo "4) Failed services"
    echo "5) All services (full list)"
    echo
    read -p "Select option (1-5): " -n 1 -r
    echo

    case $REPLY in
        1)
            systemctl list-units --type=service --state=running --no-pager
            ;;
        2)
            systemctl list-unit-files --type=service --state=enabled --no-pager
            ;;
        3)
            systemctl list-unit-files --type=service --state=disabled --no-pager
            ;;
        4)
            systemctl --failed --no-pager
            ;;
        5)
            systemctl list-units --type=service --all --no-pager | less
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
}

service_manage() {
    print_header "Service Management"
    check_root || return 1

    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        print_error "Usage: $0 service <action> <service_name>"
        echo "Actions: start, stop, restart, enable, disable, status"
        return 1
    fi

    local action="$1"
    local service="$2"

    case $action in
        start|stop|restart|enable|disable)
            systemctl "$action" "$service"
            print_success "Service $service ${action}ed"
            ;;
        status)
            systemctl status "$service" --no-pager
            ;;
        *)
            print_error "Invalid action: $action"
            return 1
            ;;
    esac
}

################################################################################
# System Monitoring Functions
################################################################################

monitor_system_info() {
    print_header "System Information"

    echo -e "${CYAN}Hostname:${NC} $(hostnamectl | grep "Static hostname" | cut -d: -f2)"
    echo -e "${CYAN}Kernel:${NC} $(uname -r)"
    echo -e "${CYAN}Architecture:${NC} $(uname -m)"
    echo -e "${CYAN}Uptime:${NC} $(uptime -p)"
    echo

    echo -e "${BOLD}${BLUE}Hardware:${NC}"
    echo -e "${CYAN}CPU:${NC} $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
    echo -e "${CYAN}Cores:${NC} $(nproc)"
    echo -e "${CYAN}RAM:${NC} $(free -h | awk '/^Mem:/ {print $2}')"
    echo

    echo -e "${BOLD}${BLUE}Boot:${NC}"
    echo -e "${CYAN}Boot time:${NC} $(systemd-analyze | grep "Startup finished")"
    echo -e "${CYAN}Firmware:${NC} $([ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS")"
    echo

    echo -e "${BOLD}${BLUE}Packages:${NC}"
    echo -e "${CYAN}Total packages:${NC} $(pacman -Q | wc -l)"
    echo -e "${CYAN}Explicit packages:${NC} $(pacman -Qe | wc -l)"
    echo -e "${CYAN}AUR packages:${NC} $(pacman -Qm | wc -l)"
}

monitor_boot_analysis() {
    print_header "Boot Performance Analysis"

    print_info "Overall boot time:"
    systemd-analyze
    echo

    print_info "Top 10 slowest services:"
    systemd-analyze blame | head -10
    echo

    read -p "Generate detailed boot chart? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local output_file="$HOME/boot-analysis-$(date +%Y%m%d-%H%M%S).svg"
        systemd-analyze plot > "$output_file"
        print_success "Boot chart saved to: $output_file"
    fi
}

monitor_resource_usage() {
    print_header "Resource Usage"

    echo -e "${BOLD}${BLUE}CPU Usage:${NC}"
    mpstat 1 1 2>/dev/null | tail -2 || top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU Usage: " 100 - $1"%"}'
    echo

    echo -e "${BOLD}${BLUE}Memory Usage:${NC}"
    free -h
    echo

    echo -e "${BOLD}${BLUE}Disk Usage:${NC}"
    df -h | grep -E "^/dev/|Filesystem"
    echo

    echo -e "${BOLD}${BLUE}Top 5 Processes by Memory:${NC}"
    ps aux --sort=-%mem | head -6
    echo

    echo -e "${BOLD}${BLUE}Top 5 Processes by CPU:${NC}"
    ps aux --sort=-%cpu | head -6
}

monitor_network() {
    print_header "Network Status"

    print_info "Network interfaces:"
    ip -brief addr
    echo

    print_info "Active connections:"
    ss -tuln | head -20
    echo

    print_info "DNS configuration:"
    cat /etc/resolv.conf 2>/dev/null || systemd-resolve --status | grep "DNS Servers" -A 3
}

################################################################################
# Backup Functions
################################################################################

backup_package_list() {
    print_header "Backup Package List"
    ensure_backup_dir

    local backup_file="$BACKUP_DIR/packages-$(date +%Y%m%d-%H%M%S).txt"
    local aur_file="$BACKUP_DIR/packages-aur-$(date +%Y%m%d-%H%M%S).txt"

    print_info "Backing up package list..."
    pacman -Qqe > "$backup_file"
    pacman -Qqm > "$aur_file" 2>/dev/null || true

    print_success "Package list saved to: $backup_file"
    print_success "AUR packages saved to: $aur_file"

    echo -e "\n${CYAN}Total packages:${NC} $(wc -l < "$backup_file")"
    echo -e "${CYAN}AUR packages:${NC} $(wc -l < "$aur_file" 2>/dev/null || echo 0)"
}

backup_config_files() {
    print_header "Backup Configuration Files"
    ensure_backup_dir

    local backup_file="$BACKUP_DIR/config-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

    print_info "Backing up configuration files..."

    # List of important config directories
    local config_paths=(
        "/etc/fstab"
        "/etc/mkinitcpio.conf"
        "/etc/pacman.conf"
        "/etc/pacman.d/mirrorlist"
        "/boot/loader"
        "/etc/systemd"
        "/etc/udev/rules.d"
        "/etc/X11/xorg.conf.d"
    )

    # Check which paths exist
    local existing_paths=()
    for path in "${config_paths[@]}"; do
        if [[ -e "$path" ]]; then
            existing_paths+=("$path")
        fi
    done

    if [[ ${#existing_paths[@]} -eq 0 ]]; then
        print_warning "No configuration files found to backup"
        return 1
    fi

    sudo tar czf "$backup_file" "${existing_paths[@]}" 2>/dev/null
    sudo chown "$USER:$USER" "$backup_file"

    print_success "Configuration backup saved to: $backup_file"
    echo -e "${CYAN}Size:${NC} $(du -h "$backup_file" | cut -f1)"
}

restore_package_list() {
    print_header "Restore Packages from List"
    check_root || return 1

    echo "Available package list backups:"
    ls -1t "$BACKUP_DIR"/packages-*.txt 2>/dev/null | head -5 | nl
    echo

    read -p "Enter backup number to restore: " backup_num
    local backup_file=$(ls -1t "$BACKUP_DIR"/packages-*.txt 2>/dev/null | sed -n "${backup_num}p")

    if [[ ! -f "$backup_file" ]]; then
        print_error "Invalid backup selection"
        return 1
    fi

    print_info "Restoring from: $backup_file"

    if confirm_action "Install $(wc -l < "$backup_file") packages?"; then
        pacman -S --needed - < "$backup_file"
        print_success "Packages restored!"
    fi
}

################################################################################
# Kernel Management Functions
################################################################################

kernel_list() {
    print_header "Installed Kernels"

    echo -e "${CYAN}Installed kernels:${NC}"
    pacman -Q | grep "^linux" | grep -v "linux-firmware\|linux-headers"
    echo

    echo -e "${CYAN}Current running kernel:${NC}"
    uname -r
    echo

    echo -e "${CYAN}Boot entries:${NC}"
    if [[ -d /boot/loader/entries ]]; then
        ls -1 /boot/loader/entries/*.conf 2>/dev/null | xargs -I {} basename {}
    elif [[ -f /boot/grub/grub.cfg ]]; then
        grep "menuentry" /boot/grub/grub.cfg | cut -d"'" -f2
    fi
}

kernel_update_initramfs() {
    print_header "Regenerate initramfs"
    check_root || return 1

    print_info "Current mkinitcpio configuration:"
    cat /etc/mkinitcpio.conf | grep "^HOOKS="
    echo

    if confirm_action "Regenerate all initramfs images?"; then
        mkinitcpio -P
        print_success "initramfs regenerated for all kernels!"
    fi
}

################################################################################
# User Management Functions
################################################################################

user_list() {
    print_header "System Users"

    echo -e "${BOLD}${BLUE}Regular Users:${NC}"
    awk -F: '$3 >= 1000 && $3 < 65534 {print $1 " (UID: " $3 ")"}' /etc/passwd
    echo

    echo -e "${BOLD}${BLUE}System Users:${NC}"
    awk -F: '$3 < 1000 && $3 != 0 {print $1 " (UID: " $3 ")"}' /etc/passwd | head -10
    echo -e "... (use 'cat /etc/passwd' for full list)"
}

user_groups() {
    print_header "User Groups"

    if [[ -z "$1" ]]; then
        read -p "Enter username: " username
    else
        username="$1"
    fi

    if ! id "$username" &>/dev/null; then
        print_error "User '$username' does not exist"
        return 1
    fi

    echo -e "${CYAN}Groups for user '$username':${NC}"
    groups "$username"
}

################################################################################
# Diagnostics Functions
################################################################################

diag_full_report() {
    print_header "Full System Diagnostics"

    local report_file="$HOME/system-report-$(date +%Y%m%d-%H%M%S).txt"

    print_info "Generating comprehensive system report..."

    {
        echo "=========================================="
        echo "ARCH LINUX SYSTEM DIAGNOSTIC REPORT"
        echo "Generated: $(date)"
        echo "=========================================="
        echo

        echo "=== SYSTEM INFORMATION ==="
        hostnamectl
        echo
        uname -a
        echo

        echo "=== KERNEL PARAMETERS ==="
        cat /proc/cmdline
        echo

        echo "=== BOOT ANALYSIS ==="
        systemd-analyze
        echo
        systemd-analyze blame | head -20
        echo

        echo "=== FAILED SERVICES ==="
        systemctl --failed
        echo

        echo "=== DISK USAGE ==="
        df -h
        echo

        echo "=== MEMORY INFO ==="
        free -h
        echo

        echo "=== PACKAGE COUNT ==="
        echo "Total packages: $(pacman -Q | wc -l)"
        echo "Explicit packages: $(pacman -Qe | wc -l)"
        echo "AUR packages: $(pacman -Qm | wc -l)"
        echo

        echo "=== RECENT ERRORS ==="
        journalctl -p err -b --no-pager | tail -50
        echo

        echo "=== NETWORK STATUS ==="
        ip addr
        echo

    } > "$report_file"

    print_success "System report saved to: $report_file"

    read -p "View report now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        less "$report_file"
    fi
}

diag_check_updates() {
    print_header "Check for Updates"

    print_info "Checking official repositories..."
    checkupdates 2>/dev/null || echo "No updates available"
    echo

    if command -v yay &>/dev/null; then
        print_info "Checking AUR (via yay)..."
        yay -Qua 2>/dev/null || echo "No AUR updates"
    elif command -v paru &>/dev/null; then
        print_info "Checking AUR (via paru)..."
        paru -Qua 2>/dev/null || echo "No AUR updates"
    fi
}

################################################################################
# Main Menu
################################################################################

show_menu() {
    clear
    print_header "Arch Linux System Manager v$SCRIPT_VERSION"

    echo -e "${BOLD}${BLUE}Package Management:${NC}"
    echo "  1) Update system"
    echo "  2) Install package"
    echo "  3) Remove package"
    echo "  4) Search packages"
    echo "  5) Package info"
    echo "  6) List orphaned packages"
    echo "  7) List explicit packages"
    echo "  8) Check AUR helper"
    echo

    echo -e "${BOLD}${GREEN}System Maintenance:${NC}"
    echo "  9) Clean package cache"
    echo " 10) Clean system logs"
    echo " 11) Check failed services"
    echo " 12) Check filesystem health"
    echo " 13) Clean temporary files"
    echo

    echo -e "${BOLD}${YELLOW}Service Management:${NC}"
    echo " 14) List services"
    echo " 15) Manage service"
    echo

    echo -e "${BOLD}${MAGENTA}System Monitoring:${NC}"
    echo " 16) System information"
    echo " 17) Boot analysis"
    echo " 18) Resource usage"
    echo " 19) Network status"
    echo

    echo -e "${BOLD}${CYAN}Backup & Restore:${NC}"
    echo " 20) Backup package list"
    echo " 21) Backup config files"
    echo " 22) Restore packages"
    echo

    echo -e "${BOLD}${RED}Kernel Management:${NC}"
    echo " 23) List kernels"
    echo " 24) Regenerate initramfs"
    echo

    echo -e "${BOLD}${BLUE}User Management:${NC}"
    echo " 25) List users"
    echo " 26) Show user groups"
    echo

    echo -e "${BOLD}${GREEN}Diagnostics:${NC}"
    echo " 27) Full system report"
    echo " 28) Check for updates"
    echo

    echo -e "${BOLD}${YELLOW}Other:${NC}"
    echo "  0) Exit"
    echo
}

main_menu() {
    while true; do
        show_menu
        read -p "Select option: " choice
        echo

        case $choice in
            1) pkg_update_system ;;
            2) read -p "Package name: " pkg; pkg_install "$pkg" ;;
            3) read -p "Package name: " pkg; pkg_remove "$pkg" ;;
            4) read -p "Search term: " term; pkg_search "$term" ;;
            5) read -p "Package name: " pkg; pkg_info "$pkg" ;;
            6) pkg_list_orphans ;;
            7) pkg_list_explicit ;;
            8) pkg_aur_helper_check ;;
            9) maint_clean_cache ;;
            10) maint_clean_logs ;;
            11) maint_check_failed ;;
            12) maint_filesystem_check ;;
            13) maint_temp_files ;;
            14) service_list ;;
            15) read -p "Action: " act; read -p "Service: " svc; service_manage "$act" "$svc" ;;
            16) monitor_system_info ;;
            17) monitor_boot_analysis ;;
            18) monitor_resource_usage ;;
            19) monitor_network ;;
            20) backup_package_list ;;
            21) backup_config_files ;;
            22) restore_package_list ;;
            23) kernel_list ;;
            24) kernel_update_initramfs ;;
            25) user_list ;;
            26) read -p "Username: " usr; user_groups "$usr" ;;
            27) diag_full_report ;;
            28) diag_check_updates ;;
            0) print_info "Exiting..."; exit 0 ;;
            *) print_error "Invalid option" ;;
        esac

        echo
        read -p "Press Enter to continue..."
    done
}

################################################################################
# Command Line Interface
################################################################################

show_help() {
    cat << EOF
Arch Linux System Manager v$SCRIPT_VERSION

Usage: $0 [command] [options]

Commands:
  Interactive Menu:
    menu                    Launch interactive menu

  Package Management:
    update                  Update system packages
    install <pkg>           Install a package
    remove <pkg>            Remove a package
    search <term>           Search for packages
    info <pkg>              Show package information
    orphans                 List and remove orphaned packages
    explicit                List explicitly installed packages

  System Maintenance:
    clean-cache             Clean package cache
    clean-logs              Clean system logs
    check-failed            Check for failed services
    check-fs                Check filesystem health
    clean-temp              Clean temporary files

  Monitoring:
    sysinfo                 Display system information
    boot-analysis           Analyze boot performance
    resources               Show resource usage
    network                 Show network status

  Backup:
    backup-packages         Backup package list
    backup-config           Backup configuration files
    restore-packages        Restore packages from backup

  Kernel:
    list-kernels            List installed kernels
    regen-initramfs         Regenerate initramfs

  Diagnostics:
    report                  Generate full system report
    check-updates           Check for available updates

  Other:
    help                    Show this help message
    version                 Show version information

Examples:
  $0 menu                 # Interactive mode
  $0 update               # Update system
  $0 install firefox      # Install Firefox
  $0 sysinfo              # Show system info

EOF
}


################################################################################
# Main Script Entry Point
################################################################################

# Create necessary directories
create_dirs

# Parse command line arguments
case "${1:-menu}" in
    # Interactive
    menu) main_menu ;;

    # Package Management
    update) pkg_update_system ;;
    install) pkg_install "$2" ;;
    remove) pkg_remove "$2" ;;
    search) pkg_search "$2" ;;
    info) pkg_info "$2" ;;
    orphans) pkg_list_orphans ;;
    explicit) pkg_list_explicit ;;

    # Maintenance
    clean-cache) maint_clean_cache ;;
    clean-logs) maint_clean_logs ;;
    check-failed) maint_check_failed ;;
    check-fs) maint_filesystem_check ;;
    clean-temp) maint_temp_files ;;

    # Monitoring
    sysinfo) monitor_system_info ;;
    boot-analysis) monitor_boot_analysis ;;
    resources) monitor_resource_usage ;;
    network) monitor_network ;;

    # Backup
    backup-packages) backup_package_list ;;
    backup-config) backup_config_files ;;
    restore-packages) restore_package_list ;;

    # Kernel
    list-kernels) kernel_list ;;
    regen-initramfs) kernel_update_initramfs ;;

    # Diagnostics
    report) diag_full_report ;;
    check-updates) diag_check_updates ;;

    # Help
    help|--help|-h) show_help ;;
    version|--version|-v) echo "Arch Linux System Manager v$SCRIPT_VERSION" ;;

    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac

exit 0
