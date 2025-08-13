# 🗄️ Comprehensive Backup System

## Overview

This backup system provides enterprise-grade backup capabilities for your server, combining your existing Mailcow email server backup with a new universal system backup solution. The system includes automated scheduling, monitoring, integrity verification, and disaster recovery capabilities.

## 🏗️ System Architecture

### Components

1. **Mailcow Backup System** (Existing)
   - Specialized backup for Mailcow email server
   - Daily and weekly automated backups
   - Complete disaster recovery capabilities

2. **Universal Backup System** (New)
   - Comprehensive system-wide backup
   - Configuration files, databases, applications
   - System information and logs

3. **Backup Manager** (New)
   - Centralized monitoring and management
   - Health checks and alerting
   - Statistics and maintenance tools

## 📁 File Structure

```
/root/
├── mailcow_backup.sh          # Existing Mailcow backup script
├── mailcow_restore.sh         # Existing Mailcow restore script
├── universal_backup.sh        # New universal backup script
├── backup_manager.sh          # New backup management script
├── setup_backup_system.sh     # New setup script
├── setup_backup_cron.sh       # Existing cron setup
└── BACKUP_SYSTEM_README.md    # This documentation

/opt/
├── mailcow-backups/           # Mailcow backup storage
└── backups/                   # Universal backup storage

/var/log/
├── universal-backup.log       # Universal backup logs
├── backup-manager.log         # Manager logs
└── mailcow-backup.log         # Mailcow backup logs

/etc/
└── backup.conf               # Backup configuration
```

## 🚀 Quick Start

### 1. Setup the Complete System

```bash
# Make scripts executable
chmod +x universal_backup.sh backup_manager.sh setup_backup_system.sh

# Run complete setup
./setup_backup_system.sh
```

### 2. Manual Backup Operations

```bash
# Mailcow backup (existing)
./mailcow_backup.sh

# Universal backup (new)
./universal_backup.sh

# Check backup status
./backup_manager.sh --status
```

### 3. Monitoring and Management

```bash
# Check backup health
./backup_manager.sh --health-check

# View backup statistics
./backup_manager.sh --stats

# List recent backups
./backup_manager.sh --list 7

# Verify backup integrity
./backup_manager.sh --verify
```

## 📋 Backup Schedules

### Automated Schedule

| Component | Frequency | Time | Script |
|-----------|-----------|------|--------|
| Mailcow Backup | Daily | 2:00 AM | `mailcow_backup.sh` |
| Mailcow Backup | Weekly | Sunday 3:00 AM | `mailcow_backup.sh` |
| Universal Backup | Weekly | Sunday 4:00 AM | `universal_backup.sh` |
| Health Check | Daily | 6:00 AM | `backup_manager.sh` |

### Manual Operations

```bash
# Immediate backup
./universal_backup.sh

# Backup with custom retention
./universal_backup.sh --retention 60

# Clean old backups
./backup_manager.sh --cleanup 30
```

## 🔧 Configuration

### Backup Configuration File

Location: `/etc/backup.conf`

```bash
# Backup directories
BACKUP_ROOT="/opt/backups"
MAILCOW_BACKUP_DIR="/opt/mailcow-backups"

# Retention settings
RETENTION_DAYS=30

# Logging
LOG_FILE="/var/log/universal-backup.log"
MANAGER_LOG_FILE="/var/log/backup-manager.log"

# Alert settings
ALERT_EMAIL="admin@yourdomain.com"

# Compression settings
COMPRESSION_LEVEL=6
```

### Customizing Settings

1. **Edit Configuration File**:
   ```bash
   nano /etc/backup.conf
   ```

2. **Update Alert Email**:
   ```bash
   sed -i 's/admin@yourdomain.com/your-email@domain.com/' /etc/backup.conf
   ```

3. **Change Retention Period**:
   ```bash
   sed -i 's/RETENTION_DAYS=30/RETENTION_DAYS=60/' /etc/backup.conf
   ```

## 📊 What Gets Backed Up

### Universal Backup Contents

#### System Information
- System specifications and hardware info
- OS release and package information
- Network configuration
- Mount points and disk usage

#### Configuration Files
- `/etc/` directory (excluding logs and cache)
- SSH configurations
- Firewall rules (iptables/ufw)
- System services configuration
- User accounts and permissions

#### Databases
- MySQL/MariaDB databases (excluding system DBs)
- PostgreSQL databases
- SQLite databases found in `/var/lib`, `/opt`, `/home`

#### Applications
- Docker containers and images
- Web server configurations (Apache/Nginx)
- SSL certificates (Let's Encrypt, custom)
- Custom applications in `/opt`

#### Logs
- System logs from `/var/log`
- Journal logs (last 7 days)
- Application logs

### Mailcow Backup Contents

- Mailcow configuration files
- MySQL database with all email data
- Docker volumes (emails, users, settings)
- SSL certificates
- System state information

## 🔍 Monitoring and Alerts

### Health Checks

The system performs daily health checks that verify:

- ✅ Backup completion status
- ✅ Backup age (freshness)
- ✅ Disk space availability
- ✅ Backup integrity (checksums)
- ✅ Cron job status
- ✅ Log file health

### Alert System

When issues are detected, the system can:

- Send email alerts to configured address
- Log detailed error information
- Provide actionable recommendations
- Track issue resolution

### Monitoring Commands

```bash
# Quick status check
./backup_manager.sh --status

# Comprehensive health check
./backup_manager.sh --health-check

# View backup statistics
./backup_manager.sh --stats

# Check recent activity
./backup_manager.sh --list 14
```

## 🛠️ Maintenance Operations

### Backup Cleanup

```bash
# Clean backups older than 30 days (default)
./backup_manager.sh --cleanup

# Clean backups older than 60 days
./backup_manager.sh --cleanup 60

# Clean backups older than 7 days
./backup_manager.sh --cleanup 7
```

### Integrity Verification

```bash
# Verify all backup integrity
./backup_manager.sh --verify

# Verify specific backup
./universal_backup.sh --verify /path/to/backup.tar.gz
```

### Log Management

```bash
# View universal backup logs
tail -f /var/log/universal-backup.log

# View backup manager logs
tail -f /var/log/backup-manager.log

# View cron job logs
tail -f /var/log/mailcow-backup-cron.log
```

## 🔄 Disaster Recovery

### Mailcow Recovery

```bash
# Full restore
./mailcow_restore.sh mailcow_backup_20250116_120000

# Dry run (preview)
./mailcow_restore.sh --dry-run mailcow_backup_20250116_120000

# Partial restore
./mailcow_restore.sh --config-only mailcow_backup_20250116_120000
./mailcow_restore.sh --database-only mailcow_backup_20250116_120000
```

### Universal Backup Recovery

```bash
# Extract backup archive
tar -xzf /opt/backups/universal_backup_20250116_120000.tar.gz

# Restore specific components
# - System configs: backup/configs/
# - Databases: backup/databases/
# - Applications: backup/applications/
# - Logs: backup/logs/
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Backup Fails Due to Disk Space

```bash
# Check available space
df -h /opt

# Clean old backups
./backup_manager.sh --cleanup

# Check what's using space
du -sh /opt/backups/* | sort -hr
```

#### 2. Cron Jobs Not Running

```bash
# Check cron service
systemctl status cron

# View cron jobs
crontab -l

# Check cron logs
tail -f /var/log/syslog | grep CRON
```

#### 3. Permission Issues

```bash
# Fix script permissions
chmod +x *.sh

# Fix backup directory permissions
chmod 750 /opt/backups /opt/mailcow-backups

# Check log file permissions
chmod 644 /var/log/universal-backup.log
```

#### 4. Database Backup Issues

```bash
# Test MySQL connection
mysql -u root -p -e "SHOW DATABASES;"

# Test PostgreSQL connection
psql -l

# Check database permissions
mysql -u root -p -e "SHOW GRANTS;"
```

### Debug Mode

```bash
# Run with verbose output
bash -x ./universal_backup.sh

# Check specific component
./universal_backup.sh --help
./backup_manager.sh --help
```

## 📈 Performance Optimization

### Storage Optimization

- **Compression**: Uses gzip compression (level 6)
- **Deduplication**: Excludes temporary and cache files
- **Retention**: Automatic cleanup of old backups
- **Incremental**: Only backs up changed files

### Time Optimization

- **Parallel Processing**: Database backups run in parallel
- **Selective Backup**: Only backs up essential data
- **Efficient Tools**: Uses rsync for large directories
- **Smart Scheduling**: Staggers backup times

## 🔒 Security Considerations

### Access Control

- Backup directories restricted to root
- Log files with appropriate permissions
- Checksums for integrity verification
- Secure configuration file permissions

### Data Protection

- No sensitive data in logs
- Encrypted backup option available
- Secure transfer methods for remote backups
- Audit trail for all operations

### Best Practices

1. **Regular Testing**: Test restore procedures monthly
2. **Off-site Storage**: Consider remote backup storage
3. **Documentation**: Keep recovery procedures updated
4. **Monitoring**: Set up alerting for backup failures
5. **Validation**: Verify backup integrity regularly

## 📞 Support and Maintenance

### Regular Maintenance Tasks

- **Weekly**: Review backup logs and statistics
- **Monthly**: Test restore procedures
- **Quarterly**: Review and update retention policies
- **Annually**: Full disaster recovery testing

### Getting Help

1. **Check Logs**: Review log files for error messages
2. **Run Diagnostics**: Use health check commands
3. **Verify Configuration**: Check backup.conf settings
4. **Test Manually**: Run backup scripts manually
5. **Review Documentation**: Check this README and system docs

### Useful Commands Reference

```bash
# System Status
./backup_manager.sh --status
./backup_manager.sh --stats

# Manual Operations
./universal_backup.sh
./mailcow_backup.sh

# Maintenance
./backup_manager.sh --cleanup 30
./backup_manager.sh --verify

# Monitoring
./backup_manager.sh --health-check
./backup_manager.sh --list 7

# Setup
./setup_backup_system.sh
./setup_backup_system.sh --test-only
```

## 🎯 Success Metrics

### Key Performance Indicators

- **Backup Success Rate**: >99%
- **Recovery Time**: <4 hours for full restore
- **Data Loss**: 0% (RPO = 24 hours)
- **Storage Efficiency**: <50% growth per year
- **Monitoring Coverage**: 100% of backup systems

### Monitoring Dashboard

The backup manager provides real-time insights into:

- Backup completion rates
- Storage utilization trends
- Error frequency and types
- Recovery time objectives
- System health scores

---

## 📝 Version History

- **v2.0** (Current): Added universal backup system and backup manager
- **v1.0**: Original Mailcow backup system

## 📄 License

This backup system is provided as-is for system administration purposes. Ensure compliance with your organization's backup and data retention policies.

---

*Last updated: $(date)*
*Backup System Version: 2.0* 