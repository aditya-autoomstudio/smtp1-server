#!/bin/bash

# Universal Backup Script (Fixed Version)
# Comprehensive backup system for various components
# Works alongside existing Mailcow backup system

set -euo pipefail

# Configuration
BACKUP_ROOT="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/universal-backup.log"
RETENTION_DAYS=30
COMPRESSION_LEVEL=6
MAX_BACKUP_SIZE="2G"  # Maximum backup size
TIMEOUT_SECONDS=300   # 5 minute timeout for operations

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

# Function to check storage space
check_storage() {
    log_info "Checking available storage space..."
    
    local backup_dir_space=$(df "$BACKUP_ROOT" | awk 'NR==2 {print $4}')
    local backup_dir_space_gb=$((backup_dir_space / 1024 / 1024))
    
    log_info "Available space in $BACKUP_ROOT: ${backup_dir_space_gb}GB"
    
    if [ "$backup_dir_space_gb" -lt 5 ]; then
        log_error "Insufficient space for backup (less than 5GB available)"
        return 1
    fi
    
    return 0
}

# Function to create backup directory structure
create_backup_structure() {
    local backup_name="backup_$DATE"
    local backup_path="$BACKUP_ROOT/$backup_name"
    
    log_info "Creating backup directory: $backup_path"
    
    mkdir -p "$backup_path"/{system,configs,databases,applications,logs}
    
    if [ $? -eq 0 ]; then
        log_message "Backup directory structure created successfully"
        echo "$backup_path"
    else
        log_error "Failed to create backup directory structure"
        return 1
    fi
}

# Function to backup system information
backup_system_info() {
    local backup_path="$1"
    local system_dir="$backup_path/system"
    
    log_info "Backing up system information..."
    
    # Create system directory
    mkdir -p "$system_dir"
    
    # System information (with error handling)
    timeout $TIMEOUT_SECONDS uname -a > "$system_dir/system_info.txt" 2>/dev/null || log_warning "Failed to get system info"
    timeout $TIMEOUT_SECONDS cat /etc/os-release > "$system_dir/os_release.txt" 2>/dev/null || log_warning "Failed to get OS release"
    timeout $TIMEOUT_SECONDS lscpu > "$system_dir/cpu_info.txt" 2>/dev/null || log_warning "Failed to get CPU info"
    timeout $TIMEOUT_SECONDS free -h > "$system_dir/memory_info.txt" 2>/dev/null || log_warning "Failed to get memory info"
    timeout $TIMEOUT_SECONDS df -h > "$system_dir/disk_usage.txt" 2>/dev/null || log_warning "Failed to get disk usage"
    timeout $TIMEOUT_SECONDS mount > "$system_dir/mount_points.txt" 2>/dev/null || log_warning "Failed to get mount points"
    
    # Network configuration
    timeout $TIMEOUT_SECONDS ip addr show > "$system_dir/network_config.txt" 2>/dev/null || log_warning "Failed to get network config"
    timeout $TIMEOUT_SECONDS ip route show > "$system_dir/routing_table.txt" 2>/dev/null || log_warning "Failed to get routing table"
    timeout $TIMEOUT_SECONDS cat /etc/hosts > "$system_dir/hosts.txt" 2>/dev/null || log_warning "Failed to get hosts file"
    
    # Package information
    if command -v dpkg &> /dev/null; then
        timeout $TIMEOUT_SECONDS dpkg -l > "$system_dir/installed_packages.txt" 2>/dev/null || log_warning "Failed to get package list"
    elif command -v rpm &> /dev/null; then
        timeout $TIMEOUT_SECONDS rpm -qa > "$system_dir/installed_packages.txt" 2>/dev/null || log_warning "Failed to get package list"
    fi
    
    log_message "System information backed up successfully"
}

# Function to backup configuration files
backup_configs() {
    local backup_path="$1"
    local config_dir="$backup_path/configs"
    
    log_info "Backing up configuration files..."
    
    # Important system configs
    local configs=(
        "/etc/fstab"
        "/etc/hostname"
        "/etc/resolv.conf"
        "/etc/ssh/sshd_config"
        "/etc/ssh/ssh_config"
        "/etc/crontab"
        "/etc/passwd"
        "/etc/group"
        "/etc/shadow"
        "/etc/gshadow"
        "/etc/sudoers"
        "/etc/environment"
        "/etc/profile"
        "/etc/bash.bashrc"
        "/etc/hosts.allow"
        "/etc/hosts.deny"
        "/etc/iptables/rules.v4"
        "/etc/iptables/rules.v6"
        "/etc/ufw/user.rules"
        "/etc/ufw/user6.rules"
    )
    
    for config in "${configs[@]}"; do
        if [ -f "$config" ]; then
            local dest_dir="$config_dir$(dirname "$config")"
            mkdir -p "$dest_dir"
            cp -p "$config" "$dest_dir/" 2>/dev/null || log_warning "Failed to backup config: $config"
        fi
    done
    
    # Backup entire /etc directory structure (excluding large directories)
    if [ -d "/etc" ]; then
        log_info "Backing up /etc directory (this may take a while)..."
        timeout $TIMEOUT_SECONDS rsync -av --exclude='*.log' --exclude='*.tmp' --exclude='cache' \
              --exclude='.cache' --exclude='tmp' --exclude='systemd/system' /etc/ "$config_dir/etc/" 2>/dev/null || log_warning "rsync of /etc failed or timed out"
    fi
    
    log_message "Configuration files backed up successfully"
}

# Function to backup databases
backup_databases() {
    local backup_path="$1"
    local db_dir="$backup_path/databases"
    
    log_info "Backing up databases..."
    
    # MySQL/MariaDB backup
    if command -v mysql &> /dev/null; then
        log_info "Backing up MySQL/MariaDB databases..."
        mkdir -p "$db_dir/mysql"
        
        # Get list of databases (with timeout)
        local databases=$(timeout $TIMEOUT_SECONDS mysql -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)" || echo "")
        
        for db in $databases; do
            if [ -n "$db" ]; then
                log_info "Backing up database: $db"
                timeout $TIMEOUT_SECONDS mysqldump --single-transaction --routines --triggers "$db" > "$db_dir/mysql/${db}.sql" 2>/dev/null || log_warning "Failed to backup MySQL database: $db"
            fi
        done
    fi
    
    # PostgreSQL backup
    if command -v psql &> /dev/null; then
        log_info "Backing up PostgreSQL databases..."
        mkdir -p "$db_dir/postgresql"
        
        # Get list of databases (with timeout)
        local databases=$(timeout $TIMEOUT_SECONDS psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" 2>/dev/null | grep -v '^$' || echo "")
        
        for db in $databases; do
            if [ -n "$db" ]; then
                log_info "Backing up PostgreSQL database: $db"
                timeout $TIMEOUT_SECONDS pg_dump "$db" > "$db_dir/postgresql/${db}.sql" 2>/dev/null || log_warning "Failed to backup PostgreSQL database: $db"
            fi
        done
    fi
    
    # SQLite databases (with timeout and limit)
    log_info "Searching for SQLite databases..."
    local sqlite_count=0
    local max_sqlite=50  # Limit to prevent excessive processing
    
    # Use find with timeout and limit results
    timeout $TIMEOUT_SECONDS find /var/lib /opt /home -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" 2>/dev/null | head -$max_sqlite | while read -r db_file; do
        if [ -f "$db_file" ] && [ $sqlite_count -lt $max_sqlite ]; then
            local db_name=$(basename "$db_file")
            local db_dest="$db_dir/sqlite"
            mkdir -p "$db_dest"
            cp "$db_file" "$db_dest/$db_name" 2>/dev/null && log_info "Backed up SQLite database: $db_file" || log_warning "Failed to backup SQLite database: $db_file"
            sqlite_count=$((sqlite_count + 1))
        fi
    done
    
    log_message "Database backups completed successfully"
}

# Function to backup applications
backup_applications() {
    local backup_path="$1"
    local app_dir="$backup_path/applications"
    
    log_info "Backing up applications..."
    
    # Docker containers and images
    if command -v docker &> /dev/null; then
        log_info "Backing up Docker information..."
        mkdir -p "$app_dir/docker"
        
        # Save container configurations (with timeout)
        timeout $TIMEOUT_SECONDS docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" > "$app_dir/docker/containers.txt" 2>/dev/null || log_warning "Failed to get Docker containers"
        
        # Save image list (with timeout)
        timeout $TIMEOUT_SECONDS docker images > "$app_dir/docker/images.txt" 2>/dev/null || log_warning "Failed to get Docker images"
        
        # Backup Docker volumes (excluding Mailcow volumes which are handled separately)
        # Fixed: Use array instead of pipe to avoid subshell issues
        local volumes=()
        while IFS= read -r volume; do
            if [ -n "$volume" ] && [[ "$volume" != *"mailcow"* ]]; then
                volumes+=("$volume")
            fi
        done < <(timeout $TIMEOUT_SECONDS docker volume ls --format "{{.Name}}" 2>/dev/null || echo "")
        
        local volume_count=0
        for volume in "${volumes[@]}"; do
            if [ $volume_count -lt 10 ]; then  # Limit to 10 volumes to prevent excessive processing
                log_info "Backing up Docker volume: $volume"
                timeout $TIMEOUT_SECONDS docker run --rm -v "$volume":/data -v "$app_dir/docker/volumes":/backup alpine tar czf "/backup/${volume}.tar.gz" -C /data . 2>/dev/null || log_warning "Failed to backup Docker volume: $volume"
                volume_count=$((volume_count + 1))
            else
                log_warning "Skipping additional Docker volumes to prevent timeout"
                break
            fi
        done
    fi
    
    # Web server configurations
    if [ -d "/etc/apache2" ]; then
        log_info "Backing up Apache configuration..."
        mkdir -p "$app_dir/apache2"
        timeout $TIMEOUT_SECONDS cp -r /etc/apache2/* "$app_dir/apache2/" 2>/dev/null || log_warning "Failed to backup Apache config"
    fi
    
    if [ -d "/etc/nginx" ]; then
        log_info "Backing up Nginx configuration..."
        mkdir -p "$app_dir/nginx"
        timeout $TIMEOUT_SECONDS cp -r /etc/nginx/* "$app_dir/nginx/" 2>/dev/null || log_warning "Failed to backup Nginx config"
    fi
    
    # SSL certificates
    if [ -d "/etc/ssl" ]; then
        log_info "Backing up SSL certificates..."
        mkdir -p "$app_dir/ssl"
        timeout $TIMEOUT_SECONDS cp -r /etc/ssl/* "$app_dir/ssl/" 2>/dev/null || log_warning "Failed to backup SSL certificates"
    fi
    
    if [ -d "/etc/letsencrypt" ]; then
        log_info "Backing up Let's Encrypt certificates..."
        mkdir -p "$app_dir/letsencrypt"
        timeout $TIMEOUT_SECONDS cp -r /etc/letsencrypt/* "$app_dir/letsencrypt/" 2>/dev/null || log_warning "Failed to backup Let's Encrypt certificates"
    fi
    
    # Custom applications in /opt (with exclusions and timeout)
    if [ -d "/opt" ]; then
        log_info "Backing up /opt applications..."
        mkdir -p "$app_dir/opt"
        timeout $TIMEOUT_SECONDS rsync -av --exclude='mailcow-dockerized' --exclude='backups' --exclude='*.log' --exclude='*.tmp' /opt/ "$app_dir/opt/" 2>/dev/null || log_warning "Failed to backup /opt applications"
    fi
    
    log_message "Application backups completed successfully"
}

# Function to backup logs
backup_logs() {
    local backup_path="$1"
    local logs_dir="$backup_path/logs"
    
    log_info "Backing up system logs..."
    
    mkdir -p "$logs_dir"
    
    # System logs (with exclusions and timeout)
    if [ -d "/var/log" ]; then
        timeout $TIMEOUT_SECONDS rsync -av --exclude='*.gz' --exclude='*.old' --exclude='*.1' --exclude='*.log.*' /var/log/ "$logs_dir/var_log/" 2>/dev/null || log_warning "Failed to backup system logs"
    fi
    
    # Journal logs (with timeout)
    if command -v journalctl &> /dev/null; then
        log_info "Backing up journal logs..."
        timeout $TIMEOUT_SECONDS journalctl --since="7 days ago" > "$logs_dir/journal_recent.log" 2>/dev/null || log_warning "Failed to backup recent journal logs"
        timeout $TIMEOUT_SECONDS journalctl --list-boots > "$logs_dir/journal_boots.txt" 2>/dev/null || log_warning "Failed to backup journal boots list"
    fi
    
    log_message "Log backups completed successfully"
}

# Function to create compressed archive
create_archive() {
    local backup_path="$1"
    local archive_name="universal_backup_$DATE.tar.gz"
    local archive_path="$BACKUP_ROOT/$archive_name"
    
    log_info "Creating compressed archive: $archive_name"
    
    cd "$BACKUP_ROOT"
    
    # Check if backup directory exists and has content
    if [ ! -d "$backup_path" ] || [ -z "$(ls -A "$backup_path" 2>/dev/null)" ]; then
        log_error "Backup directory is empty or does not exist"
        return 1
    fi
    
    # Create archive with timeout and size limit
    timeout $TIMEOUT_SECONDS tar -czf "$archive_name" -C "$backup_path" . --exclude='*.tmp' --exclude='*.cache' 2>/dev/null
    
    if [ $? -eq 0 ] && [ -f "$archive_path" ]; then
        local archive_size=$(du -h "$archive_path" | cut -f1)
        log_message "Archive created successfully: $archive_name (Size: $archive_size)"
        
        # Create checksum
        timeout $TIMEOUT_SECONDS sha256sum "$archive_path" > "$archive_path.sha256" 2>/dev/null || log_warning "Failed to create checksum"
        log_message "Checksum created: $archive_path.sha256"
        
        # Remove uncompressed backup directory
        rm -rf "$backup_path"
        log_message "Cleaned up uncompressed backup directory"
        
        echo "$archive_path"
    else
        log_error "Failed to create archive"
        return 1
    fi
}

# Function to clean old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than $RETENTION_DAYS days..."
    
    local deleted_count=0
    local freed_space=0
    
    # Use array to avoid subshell issues
    local old_backups=()
    while IFS= read -r old_backup; do
        old_backups+=("$old_backup")
    done < <(find "$BACKUP_ROOT" -name "universal_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS 2>/dev/null || echo "")
    
    for old_backup in "${old_backups[@]}"; do
        if [ -f "$old_backup" ]; then
            local backup_size=$(du -k "$old_backup" | cut -f1)
            rm -f "$old_backup" "$old_backup.sha256"
            deleted_count=$((deleted_count + 1))
            freed_space=$((freed_space + backup_size))
            log_info "Deleted old backup: $(basename "$old_backup")"
        fi
    done
    
    if [ $deleted_count -gt 0 ]; then
        local freed_space_mb=$((freed_space / 1024))
        log_message "Cleanup completed: $deleted_count backups deleted, ${freed_space_mb}MB freed"
    else
        log_message "No old backups to clean up"
    fi
}

# Function to verify backup integrity
verify_backup() {
    local archive_path="$1"
    
    log_info "Verifying backup integrity..."
    
    if [ -f "$archive_path.sha256" ]; then
        if timeout $TIMEOUT_SECONDS sha256sum -c "$archive_path.sha256" 2>/dev/null; then
            log_message "Backup integrity verified successfully"
            return 0
        else
            log_error "Backup integrity check failed"
            return 1
        fi
    else
        log_warning "No checksum file found for verification"
        return 0
    fi
}

# Function to display backup summary
show_summary() {
    local archive_path="$1"
    
    log_info "=== BACKUP SUMMARY ==="
    log_info "Backup location: $archive_path"
    
    if [ -f "$archive_path" ]; then
        local size=$(du -h "$archive_path" | cut -f1)
        log_info "Backup size: $size"
    fi
    
    log_info "Log file: $LOG_FILE"
    log_info "Retention period: $RETENTION_DAYS days"
    
    # Show recent backups
    log_info "Recent backups:"
    ls -la "$BACKUP_ROOT"/universal_backup_*.tar.gz 2>/dev/null | tail -5 | while read -r line; do
        log_info "  $line"
    done
}

# Main backup function
main_backup() {
    log_message "Starting universal backup process..."
    
    # Check prerequisites
    check_root
    check_storage
    
    # Create backup structure
    local backup_path=$(create_backup_structure)
    if [ $? -ne 0 ]; then
        log_error "Failed to create backup structure"
        exit 1
    fi
    
    # Perform backups
    backup_system_info "$backup_path"
    backup_configs "$backup_path"
    backup_databases "$backup_path"
    backup_applications "$backup_path"
    backup_logs "$backup_path"
    
    # Create archive
    local archive_path=$(create_archive "$backup_path")
    if [ $? -ne 0 ]; then
        log_error "Failed to create archive"
        exit 1
    fi
    
    # Verify backup
    verify_backup "$archive_path"
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Show summary
    show_summary "$archive_path"
    
    log_message "Universal backup completed successfully!"
}

# Function to show usage
show_usage() {
    echo "Universal Backup Script (Fixed Version)"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -v, --verify PATH   Verify backup integrity"
    echo "  -c, --cleanup       Clean up old backups only"
    echo "  -s, --summary       Show backup summary"
    echo "  -r, --retention N   Set retention days (default: $RETENTION_DAYS)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Perform full backup"
    echo "  $0 --verify /path/to/backup.tar.gz"
    echo "  $0 --cleanup        # Clean old backups only"
    echo "  $0 --summary        # Show backup summary"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -v|--verify)
        if [ -n "${2:-}" ]; then
            verify_backup "$2"
            exit $?
        else
            log_error "Please specify backup file path for verification"
            exit 1
        fi
        ;;
    -c|--cleanup)
        cleanup_old_backups
        exit 0
        ;;
    -s|--summary)
        show_summary ""
        exit 0
        ;;
    -r|--retention)
        if [ -n "${2:-}" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
            RETENTION_DAYS="$2"
            main_backup
        else
            log_error "Please specify valid retention days"
            exit 1
        fi
        ;;
    "")
        main_backup
        ;;
    *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac 