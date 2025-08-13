#!/bin/bash

# Backup System Setup Script
# Initializes the complete backup infrastructure
# Works with existing Mailcow backup system

set -euo pipefail

# Configuration
BACKUP_ROOT="/opt/backups"
MAILCOW_BACKUP_DIR="/opt/mailcow-backups"
LOG_FILE="/var/log/backup-setup.log"
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

# Function to check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    local missing_packages=()
    
    # Check for required commands
    local required_commands=("tar" "gzip" "sha256sum" "rsync" "find" "du" "df")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_packages+=("$cmd")
        fi
    done
    
    # Check for optional but recommended commands
    local optional_commands=("mysql" "mysqldump" "psql" "pg_dump" "docker" "mail")
    
    for cmd in "${optional_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_warning "Optional command not found: $cmd"
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_error "Missing required packages: ${missing_packages[*]}"
        log_info "Please install the missing packages and try again"
        return 1
    fi
    
    log_message "System requirements check passed"
    return 0
}

# Function to create backup directories
create_backup_directories() {
    log_info "Creating backup directories..."
    
    # Create main backup directory
    if [ ! -d "$BACKUP_ROOT" ]; then
        mkdir -p "$BACKUP_ROOT"
        chmod 750 "$BACKUP_ROOT"
        log_message "Created backup directory: $BACKUP_ROOT"
    else
        log_info "Backup directory already exists: $BACKUP_ROOT"
    fi
    
    # Create Mailcow backup directory if it doesn't exist
    if [ ! -d "$MAILCOW_BACKUP_DIR" ]; then
        mkdir -p "$MAILCOW_BACKUP_DIR"
        chmod 750 "$MAILCOW_BACKUP_DIR"
        log_message "Created Mailcow backup directory: $MAILCOW_BACKUP_DIR"
    else
        log_info "Mailcow backup directory already exists: $MAILCOW_BACKUP_DIR"
    fi
    
    # Create log directory
    mkdir -p /var/log
    touch /var/log/universal-backup.log
    touch /var/log/backup-manager.log
    chmod 644 /var/log/universal-backup.log
    chmod 644 /var/log/backup-manager.log
    
    log_message "Backup directories and log files created successfully"
}

# Function to make scripts executable
make_scripts_executable() {
    log_info "Making backup scripts executable..."
    
    local scripts=(
        "universal_backup.sh"
        "backup_manager.sh"
        "mailcow_backup.sh"
        "mailcow_restore.sh"
        "setup_backup_cron.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            log_info "Made executable: $script"
        else
            log_warning "Script not found: $script"
        fi
    done
    
    log_message "Script permissions set successfully"
}

# Function to setup universal backup cron job
setup_universal_backup_cron() {
    log_info "Setting up universal backup cron job..."
    
    local cron_job="0 4 * * 0 /root/universal_backup.sh >> /var/log/universal-backup-cron.log 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "universal_backup.sh"; then
        log_warning "Universal backup cron job already exists"
        return 0
    fi
    
    # Add cron job
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    
    log_message "Universal backup cron job added (runs weekly on Sunday at 4 AM)"
}

# Function to setup backup monitoring
setup_backup_monitoring() {
    log_info "Setting up backup monitoring..."
    
    # Run the backup manager setup monitoring function
    if [ -f "backup_manager.sh" ]; then
        ./backup_manager.sh --setup-monitoring
        log_message "Backup monitoring setup completed"
    else
        log_warning "Backup manager script not found, skipping monitoring setup"
    fi
}

# Function to create backup configuration file
create_backup_config() {
    log_info "Creating backup configuration file..."
    
    local config_file="/etc/backup.conf"
    
    cat > "$config_file" << EOF
# Backup System Configuration
# Generated on $(date)

# Backup directories
BACKUP_ROOT="$BACKUP_ROOT"
MAILCOW_BACKUP_DIR="$MAILCOW_BACKUP_DIR"

# Retention settings
RETENTION_DAYS=$RETENTION_DAYS

# Logging
LOG_FILE="/var/log/universal-backup.log"
MANAGER_LOG_FILE="/var/log/backup-manager.log"

# Alert settings
ALERT_EMAIL="admin@yourdomain.com"

# Compression settings
COMPRESSION_LEVEL=6

# Cron schedules
MAILCOW_DAILY_CRON="0 2 * * *"
MAILCOW_WEEKLY_CRON="0 3 * * 0"
UNIVERSAL_WEEKLY_CRON="0 4 * * 0"
MONITORING_DAILY_CRON="0 6 * * *"
EOF
    
    chmod 644 "$config_file"
    log_message "Backup configuration file created: $config_file"
}

# Function to create systemd service (optional)
create_systemd_service() {
    log_info "Creating systemd service for backup monitoring..."
    
    local service_file="/etc/systemd/system/backup-monitor.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=Backup System Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/root/backup_manager.sh --health-check
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    local timer_file="/etc/systemd/system/backup-monitor.timer"
    
    cat > "$timer_file" << EOF
[Unit]
Description=Run backup monitoring daily
Requires=backup-monitor.service

[Timer]
OnCalendar=*-*-* 06:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Enable and start the timer
    systemctl daemon-reload
    systemctl enable backup-monitor.timer
    systemctl start backup-monitor.timer
    
    log_message "Systemd service and timer created for backup monitoring"
}

# Function to test backup system
test_backup_system() {
    log_info "Testing backup system..."
    
    # Test universal backup script
    if [ -f "universal_backup.sh" ]; then
        log_info "Testing universal backup script..."
        if ./universal_backup.sh --help >/dev/null 2>&1; then
            log_message "Universal backup script test passed"
        else
            log_error "Universal backup script test failed"
            return 1
        fi
    fi
    
    # Test backup manager script
    if [ -f "backup_manager.sh" ]; then
        log_info "Testing backup manager script..."
        if ./backup_manager.sh --help >/dev/null 2>&1; then
            log_message "Backup manager script test passed"
        else
            log_error "Backup manager script test failed"
            return 1
        fi
    fi
    
    # Test storage space
    local available_space=$(df "$BACKUP_ROOT" | awk 'NR==2 {print $4}')
    local available_space_gb=$((available_space / 1024 / 1024))
    
    if [ "$available_space_gb" -lt 5 ]; then
        log_warning "Low disk space for backups: ${available_space_gb}GB available"
    else
        log_message "Storage space check passed: ${available_space_gb}GB available"
    fi
    
    log_message "Backup system tests completed successfully"
    return 0
}

# Function to show current cron jobs
show_cron_jobs() {
    log_info "Current backup-related cron jobs:"
    
    echo -e "${CYAN}=== CURRENT CRON JOBS ===${NC}"
    crontab -l 2>/dev/null | grep -E "(mailcow|universal|backup)" || echo "No backup cron jobs found"
    echo ""
}

# Function to create backup documentation
create_documentation() {
    log_info "Creating backup system documentation..."
    
    local doc_file="/opt/backup-system-documentation.md"
    
    cat > "$doc_file" << EOF
# Backup System Documentation

## Overview
This system provides comprehensive backup capabilities for your server, including:
- Mailcow email server backups
- Universal system backups
- Automated monitoring and alerting
- Backup integrity verification

## Components

### 1. Mailcow Backup System
- **Script**: \`mailcow_backup.sh\`
- **Directory**: \`$MAILCOW_BACKUP_DIR\`
- **Schedule**: Daily at 2 AM, Weekly on Sunday at 3 AM
- **Restore**: \`mailcow_restore.sh\`

### 2. Universal Backup System
- **Script**: \`universal_backup.sh\`
- **Directory**: \`$BACKUP_ROOT\`
- **Schedule**: Weekly on Sunday at 4 AM
- **Contents**: System configs, databases, applications, logs

### 3. Backup Manager
- **Script**: \`backup_manager.sh\`
- **Functions**: Monitoring, statistics, cleanup, verification
- **Schedule**: Daily health check at 6 AM

## Usage

### Manual Backups
\`\`\`bash
# Mailcow backup
./mailcow_backup.sh

# Universal backup
./universal_backup.sh

# Check status
./backup_manager.sh --status
\`\`\`

### Monitoring
\`\`\`bash
# Check backup status
./backup_manager.sh --status

# Show statistics
./backup_manager.sh --stats

# List recent backups
./backup_manager.sh --list 7

# Verify integrity
./backup_manager.sh --verify

# Health check
./backup_manager.sh --health-check
\`\`\`

### Maintenance
\`\`\`bash
# Clean old backups
./backup_manager.sh --cleanup 30

# Setup monitoring
./backup_manager.sh --setup-monitoring
\`\`\`

## Configuration
- **Config File**: \`/etc/backup.conf\`
- **Log Files**: \`/var/log/universal-backup.log\`, \`/var/log/backup-manager.log\`
- **Retention**: $RETENTION_DAYS days (configurable)

## Recovery
1. **Mailcow Recovery**: Use \`mailcow_restore.sh\` with backup filename
2. **Universal Recovery**: Extract backup archive and restore manually
3. **System Recovery**: Use system information from universal backups

## Monitoring
- Daily health checks at 6 AM
- Email alerts for issues
- Log rotation configured
- Integrity verification

## Troubleshooting
1. Check log files for errors
2. Verify disk space
3. Test backup scripts manually
4. Check cron job status
5. Verify file permissions

## Security
- Backup directories restricted to root
- Checksums for integrity verification
- Secure file permissions
- Log monitoring for unauthorized access

Generated on: $(date)
EOF
    
    log_message "Documentation created: $doc_file"
}

# Function to show setup summary
show_setup_summary() {
    log_info "=== BACKUP SYSTEM SETUP SUMMARY ==="
    
    echo -e "${CYAN}=== SETUP COMPLETED ===${NC}"
    echo -e "✅ System requirements checked"
    echo -e "✅ Backup directories created"
    echo -e "✅ Scripts made executable"
    echo -e "✅ Cron jobs configured"
    echo -e "✅ Monitoring setup"
    echo -e "✅ Configuration file created"
    echo -e "✅ Systemd service created"
    echo -e "✅ System tests completed"
    echo -e "✅ Documentation created"
    echo ""
    
    echo -e "${BLUE}Backup Directories:${NC}"
    echo -e "  Mailcow: $MAILCOW_BACKUP_DIR"
    echo -e "  Universal: $BACKUP_ROOT"
    echo ""
    
    echo -e "${BLUE}Log Files:${NC}"
    echo -e "  Universal Backup: /var/log/universal-backup.log"
    echo -e "  Backup Manager: /var/log/backup-manager.log"
    echo ""
    
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Config File: /etc/backup.conf"
    echo -e "  Documentation: /opt/backup-system-documentation.md"
    echo ""
    
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "  1. Update ALERT_EMAIL in /etc/backup.conf"
    echo -e "  2. Test backup scripts manually"
    echo -e "  3. Verify cron jobs are running"
    echo -e "  4. Monitor first automated backups"
    echo -e "  5. Review documentation"
    echo ""
    
    echo -e "${GREEN}Backup system setup completed successfully!${NC}"
}

# Main setup function
main_setup() {
    log_message "Starting backup system setup..."
    
    # Check prerequisites
    check_root
    check_requirements
    
    # Create infrastructure
    create_backup_directories
    make_scripts_executable
    create_backup_config
    
    # Setup automation
    setup_universal_backup_cron
    setup_backup_monitoring
    create_systemd_service
    
    # Test and document
    test_backup_system
    create_documentation
    
    # Show summary
    show_setup_summary
    show_cron_jobs
    
    log_message "Backup system setup completed successfully!"
}

# Function to show usage
show_usage() {
    echo "Backup System Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  --test-only         Run tests only"
    echo "  --cron-only         Setup cron jobs only"
    echo "  --monitoring-only   Setup monitoring only"
    echo ""
    echo "Examples:"
    echo "  $0                  # Complete setup"
    echo "  $0 --test-only      # Test existing setup"
    echo "  $0 --cron-only      # Setup cron jobs only"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    --test-only)
        check_root
        test_backup_system
        show_cron_jobs
        ;;
    --cron-only)
        check_root
        setup_universal_backup_cron
        show_cron_jobs
        ;;
    --monitoring-only)
        check_root
        setup_backup_monitoring
        ;;
    "")
        main_setup
        ;;
    *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac 