#!/bin/bash

# Backup Manager Script
# Comprehensive backup monitoring and management system
# Coordinates Mailcow and Universal backup systems

set -euo pipefail

# Configuration
MAILCOW_BACKUP_DIR="/opt/mailcow-backups"
UNIVERSAL_BACKUP_DIR="/opt/backups"
LOG_FILE="/var/log/backup-manager.log"
ALERT_EMAIL="admin@yourdomain.com"
RETENTION_DAYS=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Function to check backup status
check_backup_status() {
    log_info "Checking backup status..."
    
    local mailcow_status="❌"
    local universal_status="❌"
    local issues=()
    
    # Check Mailcow backups
    if [ -d "$MAILCOW_BACKUP_DIR" ]; then
        local latest_mailcow=$(find "$MAILCOW_BACKUP_DIR" -name "mailcow_backup_*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [ -n "$latest_mailcow" ]; then
            local mailcow_age=$(( ($(date +%s) - $(stat -c %Y "$latest_mailcow")) / 86400 ))
            
            if [ $mailcow_age -le 2 ]; then
                mailcow_status="✅"
                log_info "Mailcow backup: OK (age: ${mailcow_age} days)"
            else
                mailcow_status="⚠️"
                issues+=("Mailcow backup is ${mailcow_age} days old")
                log_warning "Mailcow backup is ${mailcow_age} days old"
            fi
        else
            issues+=("No Mailcow backups found")
            log_error "No Mailcow backups found"
        fi
    else
        issues+=("Mailcow backup directory not found")
        log_error "Mailcow backup directory not found: $MAILCOW_BACKUP_DIR"
    fi
    
    # Check Universal backups
    if [ -d "$UNIVERSAL_BACKUP_DIR" ]; then
        local latest_universal=$(find "$UNIVERSAL_BACKUP_DIR" -name "universal_backup_*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [ -n "$latest_universal" ]; then
            local universal_age=$(( ($(date +%s) - $(stat -c %Y "$latest_universal")) / 86400 ))
            
            if [ $universal_age -le 7 ]; then
                universal_status="✅"
                log_info "Universal backup: OK (age: ${universal_age} days)"
            else
                universal_status="⚠️"
                issues+=("Universal backup is ${universal_age} days old")
                log_warning "Universal backup is ${universal_age} days old"
            fi
        else
            issues+=("No Universal backups found")
            log_error "No Universal backups found"
        fi
    else
        issues+=("Universal backup directory not found")
        log_error "Universal backup directory not found: $UNIVERSAL_BACKUP_DIR"
    fi
    
    # Display status
    echo -e "${CYAN}=== BACKUP STATUS ===${NC}"
    echo -e "Mailcow Backup: $mailcow_status"
    echo -e "Universal Backup: $universal_status"
    echo ""
    
    if [ ${#issues[@]} -gt 0 ]; then
        echo -e "${YELLOW}Issues Found:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  • $issue"
        done
        echo ""
        return 1
    else
        echo -e "${GREEN}All backup systems are healthy!${NC}"
        echo ""
        return 0
    fi
}

# Function to show backup statistics
show_backup_stats() {
    log_info "Generating backup statistics..."
    
    echo -e "${CYAN}=== BACKUP STATISTICS ===${NC}"
    
    # Mailcow backup stats
    if [ -d "$MAILCOW_BACKUP_DIR" ]; then
        local mailcow_count=$(find "$MAILCOW_BACKUP_DIR" -name "mailcow_backup_*.tar.gz" -type f | wc -l)
        local mailcow_size=$(du -sh "$MAILCOW_BACKUP_DIR" 2>/dev/null | cut -f1)
        local latest_mailcow=$(find "$MAILCOW_BACKUP_DIR" -name "mailcow_backup_*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        
        echo -e "${BLUE}Mailcow Backups:${NC}"
        echo -e "  Count: $mailcow_count"
        echo -e "  Total Size: $mailcow_size"
        
        if [ -n "$latest_mailcow" ]; then
            local mailcow_age=$(( ($(date +%s) - $(stat -c %Y "$latest_mailcow")) / 86400 ))
            local latest_size=$(du -h "$latest_mailcow" | cut -f1)
            echo -e "  Latest: $(basename "$latest_mailcow") (${mailcow_age} days old, $latest_size)"
        fi
        echo ""
    fi
    
    # Universal backup stats
    if [ -d "$UNIVERSAL_BACKUP_DIR" ]; then
        local universal_count=$(find "$UNIVERSAL_BACKUP_DIR" -name "universal_backup_*.tar.gz" -type f | wc -l)
        local universal_size=$(du -sh "$UNIVERSAL_BACKUP_DIR" 2>/dev/null | cut -f1)
        local latest_universal=$(find "$UNIVERSAL_BACKUP_DIR" -name "universal_backup_*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        
        echo -e "${BLUE}Universal Backups:${NC}"
        echo -e "  Count: $universal_count"
        echo -e "  Total Size: $universal_size"
        
        if [ -n "$latest_universal" ]; then
            local universal_age=$(( ($(date +%s) - $(stat -c %Y "$latest_universal")) / 86400 ))
            local latest_size=$(du -h "$latest_universal" | cut -f1)
            echo -e "  Latest: $(basename "$latest_universal") (${universal_age} days old, $latest_size)"
        fi
        echo ""
    fi
    
    # Storage statistics
    echo -e "${BLUE}Storage Information:${NC}"
    df -h | grep -E '^/dev/' | while read -r line; do
        echo -e "  $line"
    done
    echo ""
}

# Function to list recent backups
list_recent_backups() {
    local days="${1:-7}"
    
    log_info "Listing backups from the last $days days..."
    
    echo -e "${CYAN}=== RECENT BACKUPS (Last $days days) ===${NC}"
    
    # Mailcow backups
    if [ -d "$MAILCOW_BACKUP_DIR" ]; then
        echo -e "${BLUE}Mailcow Backups:${NC}"
        find "$MAILCOW_BACKUP_DIR" -name "mailcow_backup_*.tar.gz" -type f -mtime -$days -printf '%T@ %p\n' | sort -n | while read -r line; do
            local timestamp=$(echo "$line" | cut -d' ' -f1)
            local filepath=$(echo "$line" | cut -d' ' -f2-)
            local date=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
            local size=$(du -h "$filepath" | cut -f1)
            echo -e "  $date - $(basename "$filepath") ($size)"
        done
        echo ""
    fi
    
    # Universal backups
    if [ -d "$UNIVERSAL_BACKUP_DIR" ]; then
        echo -e "${BLUE}Universal Backups:${NC}"
        find "$UNIVERSAL_BACKUP_DIR" -name "universal_backup_*.tar.gz" -type f -mtime -$days -printf '%T@ %p\n' | sort -n | while read -r line; do
            local timestamp=$(echo "$line" | cut -d' ' -f1)
            local filepath=$(echo "$line" | cut -d' ' -f2-)
            local date=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
            local size=$(du -h "$filepath" | cut -f1)
            echo -e "  $date - $(basename "$filepath") ($size)"
        done
        echo ""
    fi
}

# Function to clean old backups
cleanup_old_backups() {
    local days="${1:-$RETENTION_DAYS}"
    
    log_info "Cleaning up backups older than $days days..."
    
    local deleted_count=0
    local freed_space=0
    
    # Clean Mailcow backups
    if [ -d "$MAILCOW_BACKUP_DIR" ]; then
        find "$MAILCOW_BACKUP_DIR" -name "mailcow_backup_*.tar.gz" -type f -mtime +$days | while read -r old_backup; do
            local backup_size=$(du -k "$old_backup" | cut -f1)
            rm -f "$old_backup" "$old_backup.sha256" 2>/dev/null
            deleted_count=$((deleted_count + 1))
            freed_space=$((freed_space + backup_size))
            log_info "Deleted old Mailcow backup: $(basename "$old_backup")"
        done
    fi
    
    # Clean Universal backups
    if [ -d "$UNIVERSAL_BACKUP_DIR" ]; then
        find "$UNIVERSAL_BACKUP_DIR" -name "universal_backup_*.tar.gz" -type f -mtime +$days | while read -r old_backup; do
            local backup_size=$(du -k "$old_backup" | cut -f1)
            rm -f "$old_backup" "$old_backup.sha256" 2>/dev/null
            deleted_count=$((deleted_count + 1))
            freed_space=$((freed_space + backup_size))
            log_info "Deleted old Universal backup: $(basename "$old_backup")"
        done
    fi
    
    if [ $deleted_count -gt 0 ]; then
        local freed_space_mb=$((freed_space / 1024))
        log_message "Cleanup completed: $deleted_count backups deleted, ${freed_space_mb}MB freed"
    else
        log_message "No old backups to clean up"
    fi
}

# Function to verify backup integrity
verify_backups() {
    log_info "Verifying backup integrity..."
    
    local verified_count=0
    local failed_count=0
    
    echo -e "${CYAN}=== BACKUP INTEGRITY CHECK ===${NC}"
    
    # Verify Mailcow backups
    if [ -d "$MAILCOW_BACKUP_DIR" ]; then
        echo -e "${BLUE}Verifying Mailcow backups:${NC}"
        find "$MAILCOW_BACKUP_DIR" -name "mailcow_backup_*.tar.gz" -type f | head -5 | while read -r backup; do
            local checksum_file="$backup.sha256"
            if [ -f "$checksum_file" ]; then
                if sha256sum -c "$checksum_file" >/dev/null 2>&1; then
                    echo -e "  ✅ $(basename "$backup")"
                    verified_count=$((verified_count + 1))
                else
                    echo -e "  ❌ $(basename "$backup") - Checksum mismatch"
                    failed_count=$((failed_count + 1))
                fi
            else
                echo -e "  ⚠️  $(basename "$backup") - No checksum file"
            fi
        done
    fi
    
    # Verify Universal backups
    if [ -d "$UNIVERSAL_BACKUP_DIR" ]; then
        echo -e "${BLUE}Verifying Universal backups:${NC}"
        find "$UNIVERSAL_BACKUP_DIR" -name "universal_backup_*.tar.gz" -type f | head -5 | while read -r backup; do
            local checksum_file="$backup.sha256"
            if [ -f "$checksum_file" ]; then
                if sha256sum -c "$checksum_file" >/dev/null 2>&1; then
                    echo -e "  ✅ $(basename "$backup")"
                    verified_count=$((verified_count + 1))
                else
                    echo -e "  ❌ $(basename "$backup") - Checksum mismatch"
                    failed_count=$((failed_count + 1))
                fi
            else
                echo -e "  ⚠️  $(basename "$backup") - No checksum file"
            fi
        done
    fi
    
    echo ""
    echo -e "Verified: $verified_count, Failed: $failed_count"
    
    if [ $failed_count -gt 0 ]; then
        log_error "Backup integrity check found $failed_count failed backups"
        return 1
    else
        log_message "All checked backups passed integrity verification"
        return 0
    fi
}

# Function to send alert email
send_alert() {
    local subject="$1"
    local message="$2"
    
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
        log_info "Alert email sent to $ALERT_EMAIL"
    else
        log_warning "Mail command not available, cannot send alert email"
    fi
}

# Function to run backup health check
run_health_check() {
    log_info "Running comprehensive backup health check..."
    
    local issues=()
    
    # Check backup status
    if ! check_backup_status; then
        issues+=("Backup status check failed")
    fi
    
    # Check storage space
    local available_space=$(df /opt | awk 'NR==2 {print $4}')
    local available_space_gb=$((available_space / 1024 / 1024))
    
    if [ "$available_space_gb" -lt 10 ]; then
        issues+=("Low disk space: ${available_space_gb}GB available")
    fi
    
    # Check backup integrity
    if ! verify_backups; then
        issues+=("Backup integrity check failed")
    fi
    
    # Check cron jobs
    if ! crontab -l 2>/dev/null | grep -q "mailcow_backup\|universal_backup"; then
        issues+=("Backup cron jobs not found")
    fi
    
    # Send alert if issues found
    if [ ${#issues[@]} -gt 0 ]; then
        local alert_message="Backup health check found issues:\n\n"
        for issue in "${issues[@]}"; do
            alert_message+="• $issue\n"
        done
        alert_message+="\nPlease check the backup system immediately."
        
        send_alert "Backup System Alert" "$alert_message"
        log_error "Health check completed with issues"
        return 1
    else
        log_message "Health check completed successfully - all systems operational"
        return 0
    fi
}

# Function to setup monitoring cron job
setup_monitoring() {
    log_info "Setting up backup monitoring..."
    
    local monitor_script="/usr/local/bin/backup-monitor.sh"
    
    # Create monitoring script
    cat > "$monitor_script" << 'EOF'
#!/bin/bash
# Backup monitoring script for cron

/root/backup_manager.sh --health-check >> /var/log/backup-monitor.log 2>&1
EOF
    
    chmod +x "$monitor_script"
    
    # Add to crontab if not already present
    if ! crontab -l 2>/dev/null | grep -q "backup-monitor"; then
        (crontab -l 2>/dev/null; echo "0 6 * * * $monitor_script") | crontab -
        log_message "Backup monitoring cron job added (runs daily at 6 AM)"
    else
        log_info "Backup monitoring cron job already exists"
    fi
}

# Function to show usage
show_usage() {
    echo "Backup Manager Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -s, --status            Check backup status"
    echo "  -t, --stats             Show backup statistics"
    echo "  -l, --list [DAYS]       List recent backups (default: 7 days)"
    echo "  -c, --cleanup [DAYS]    Clean old backups (default: $RETENTION_DAYS days)"
    echo "  -v, --verify            Verify backup integrity"
    echo "  --health-check          Run comprehensive health check"
    echo "  --setup-monitoring      Setup monitoring cron job"
    echo ""
    echo "Examples:"
    echo "  $0 --status             # Check backup status"
    echo "  $0 --stats              # Show backup statistics"
    echo "  $0 --list 14            # List backups from last 14 days"
    echo "  $0 --cleanup 60         # Clean backups older than 60 days"
    echo "  $0 --verify             # Verify backup integrity"
    echo "  $0 --health-check       # Run health check"
    echo "  $0 --setup-monitoring   # Setup monitoring"
}

# Main function
main() {
    check_root
    
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -s|--status)
            check_backup_status
            ;;
        -t|--stats)
            show_backup_stats
            ;;
        -l|--list)
            local days="${2:-7}"
            list_recent_backups "$days"
            ;;
        -c|--cleanup)
            local days="${2:-$RETENTION_DAYS}"
            cleanup_old_backups "$days"
            ;;
        -v|--verify)
            verify_backups
            ;;
        --health-check)
            run_health_check
            ;;
        --setup-monitoring)
            setup_monitoring
            ;;
        "")
            check_backup_status
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 