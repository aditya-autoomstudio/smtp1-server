# 🚀 SMTP Server with Comprehensive Backup System

A production-ready SMTP server with enterprise-grade backup and monitoring capabilities, built on Ubuntu with Mailcow email server and universal backup system.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Backup System](#backup-system)
- [Monitoring](#monitoring)
- [Usage](#usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This repository contains a complete SMTP server setup with:
- **Mailcow Email Server** - Full-featured email server with web interface
- **Universal Backup System** - Comprehensive system-wide backup solution
- **Automated Monitoring** - Health checks and alerting
- **Production-Ready** - Security hardened and optimized for production use

## ✨ Features

### 🗄️ Email Server (Mailcow)
- **Complete Email Solution** - SMTP, IMAP, POP3, Webmail
- **Web Administration** - User-friendly web interface
- **Security Features** - SPF, DKIM, DMARC, TLS encryption
- **Spam Protection** - Rspamd integration
- **Virus Scanning** - ClamAV integration
- **Multi-domain Support** - Host multiple domains
- **User Management** - Complete user and domain administration

### 🗄️ Backup System
- **Universal Backup Script** - System-wide backup solution
- **Mailcow Backup** - Specialized email server backup
- **Automated Scheduling** - Daily and weekly backups
- **Health Monitoring** - Backup integrity verification
- **Retention Management** - Configurable retention policies
- **Compression & Encryption** - Efficient storage and security

### 🔍 Monitoring & Alerting
- **Health Checks** - Automated system monitoring
- **Backup Verification** - Integrity and completion checks
- **Email Alerts** - Notification system for issues
- **Log Management** - Centralized logging and analysis
- **Performance Metrics** - System performance tracking

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SMTP Server Architecture                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Web Interface │    │   Email Clients │                │
│  │   (Mailcow UI)  │    │   (SMTP/IMAP)   │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           └───────────────────────┼────────────────────────┘
│                                   │
│  ┌─────────────────────────────────┼────────────────────────┐
│  │         Mailcow Email Server    │                        │
│  │  ┌─────────────┐ ┌─────────────┐│                        │
│  │  │   Postfix   │ │   Dovecot   ││                        │
│  │  │   (SMTP)    │ │   (IMAP)    ││                        │
│  │  └─────────────┘ └─────────────┘│                        │
│  │  ┌─────────────┐ ┌─────────────┐│                        │
│  │  │   Rspamd    │ │   ClamAV    ││                        │
│  │  │  (Spam)     │ │  (Virus)    ││                        │
│  │  └─────────────┘ └─────────────┘│                        │
│  └─────────────────────────────────┘                        │
│                                   │                        │
│  ┌─────────────────────────────────┼────────────────────────┐
│  │         Backup System           │                        │
│  │  ┌─────────────┐ ┌─────────────┐│                        │
│  │  │ Universal   │ │   Mailcow   ││                        │
│  │  │   Backup    │ │   Backup    ││                        │
│  │  └─────────────┘ └─────────────┘│                        │
│  │  ┌─────────────┐ ┌─────────────┐│                        │
│  │  │   Backup    │ │   Health    ││                        │
│  │  │   Manager   │ │   Monitor   ││                        │
│  │  └─────────────┘ └─────────────┘│                        │
│  └─────────────────────────────────┘                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Installation

### Prerequisites
- Ubuntu 20.04+ or Debian 11+
- Minimum 4GB RAM
- 20GB+ available disk space
- Root access

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/smtp-server.git
   cd smtp-server
   ```

2. **Run the setup script:**
   ```bash
   chmod +x setup_backup_system.sh
   ./setup_backup_system.sh
   ```

3. **Access the web interface:**
   - URL: `https://your-server-ip`
   - Default admin: `admin`
   - Default password: `moohoo`

## 🗄️ Backup System

### Components

#### Universal Backup Script (`universal_backup.sh`)
Comprehensive system-wide backup solution that includes:
- **System Information** - Hardware specs, OS details, network config
- **Configuration Files** - Complete `/etc/` directory backup
- **Databases** - MySQL, PostgreSQL, SQLite databases
- **Applications** - Docker containers, web servers, SSL certificates
- **Logs** - System logs and journal entries

#### Mailcow Backup Script (`mailcow_backup.sh`)
Specialized backup for the Mailcow email server:
- **Email Data** - All user emails and attachments
- **Configuration** - Mailcow settings and configurations
- **Databases** - Mailcow-specific databases
- **SSL Certificates** - Email server certificates

#### Backup Manager (`backup_manager.sh`)
Centralized backup monitoring and management:
- **Status Monitoring** - Check backup health and completion
- **Health Alerts** - Email notifications for backup issues
- **Retention Management** - Automatic cleanup of old backups
- **Integrity Verification** - Checksum validation

### Usage

#### Manual Backup
```bash
# Run universal backup
./universal_backup.sh

# Run Mailcow backup
./mailcow_backup.sh

# Check backup status
./backup_manager.sh --status
```

#### Automated Backups
The system includes automated scheduling:
- **Daily Mailcow backups** at 2:00 AM
- **Weekly universal backups** on Sundays at 4:00 AM
- **Daily health checks** at 6:00 AM

#### Backup Verification
```bash
# Verify backup integrity
./universal_backup.sh --verify /path/to/backup.tar.gz

# Show backup summary
./universal_backup.sh --summary

# Clean old backups
./universal_backup.sh --cleanup
```

## 🔍 Monitoring

### Health Checks
The system includes comprehensive monitoring:
- **Backup completion verification**
- **Disk space monitoring**
- **Service health checks**
- **Email delivery monitoring**

### Alerting
- **Email notifications** for backup failures
- **System health alerts**
- **Performance warnings**
- **Security notifications**

### Logs
- **Centralized logging** in `/var/log/`
- **Backup logs** with detailed progress
- **System logs** for troubleshooting
- **Application logs** for debugging

## 📖 Usage

### Email Server Management

#### Web Interface
1. Access `https://your-server-ip`
2. Login with admin credentials
3. Manage domains, users, and settings

#### Command Line
```bash
# Check Mailcow status
cd /opt/mailcow-dockerized
./update.sh

# View logs
docker-compose logs -f

# Restart services
docker-compose restart
```

### Backup Management

#### Check Status
```bash
./backup_manager.sh --status
```

#### Manual Backup
```bash
# Full system backup
./universal_backup.sh

# Email server backup
./mailcow_backup.sh
```

#### Restore from Backup
```bash
# Extract backup
tar -xzf universal_backup_YYYYMMDD_HHMMSS.tar.gz

# Restore specific components
# (See documentation for detailed restore procedures)
```

## ⚙️ Configuration

### Backup Configuration
Edit the backup scripts to customize:
- **Retention periods** (default: 30 days)
- **Backup locations** (default: `/opt/backups`)
- **Compression settings**
- **Exclusion patterns**

### Email Server Configuration
Mailcow configuration files:
- `/opt/mailcow-dockerized/data/conf/` - Main configuration
- `/opt/mailcow-dockerized/mailcow.conf` - Environment settings
- Web interface for user management

### Monitoring Configuration
- **Alert email addresses** in backup scripts
- **Health check intervals** in cron jobs
- **Log rotation** settings

## 🔧 Troubleshooting

### Common Issues

#### Backup Failures
```bash
# Check backup logs
tail -f /var/log/universal-backup.log
tail -f /var/log/mailcow-backup.log

# Verify disk space
df -h /opt/backups

# Check backup status
./backup_manager.sh --status
```

#### Email Server Issues
```bash
# Check Mailcow status
cd /opt/mailcow-dockerized
docker-compose ps

# View service logs
docker-compose logs -f postfix
docker-compose logs -f dovecot

# Restart services
docker-compose restart
```

#### Performance Issues
```bash
# Check system resources
htop
df -h
free -h

# Monitor email queue
cd /opt/mailcow-dockerized
docker-compose exec postfix postqueue -p
```

### Log Locations
- **Backup logs**: `/var/log/universal-backup.log`
- **Mailcow logs**: `/opt/mailcow-dockerized/log/`
- **System logs**: `/var/log/syslog`
- **Application logs**: `/var/log/`

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Development Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/smtp-server.git

# Create development environment
# (See development documentation)
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Mailcow Team** - For the excellent email server solution
- **Open Source Community** - For the tools and libraries used
- **Contributors** - For improvements and bug reports

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/smtp-server/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/smtp-server/wiki)
- **Email**: support@yourdomain.com

---

**⭐ Star this repository if you find it useful!**

**🔔 Don't forget to set up your backup monitoring and alerts!** 