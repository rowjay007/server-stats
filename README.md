# Server Statistics Monitoring Scripts

**Author:** Rowjay  
**Version:** 1.0.0  
**License:** MIT  

A comprehensive collection of Bash scripts for monitoring and reporting essential server performance metrics on Linux and Unix-like systems.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Scripts](#scripts)
- [Installation](#installation)
- [Usage](#usage)
- [Output Examples](#output-examples)
- [System Requirements](#system-requirements)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🔍 Overview

This project provides two powerful server monitoring scripts designed to analyze and report essential server performance metrics without requiring external dependencies beyond standard system utilities.

### Core Capabilities
- **CPU Usage Analysis** - Real-time percentage utilization across all cores
- **Memory Statistics** - Detailed RAM and swap usage with percentages
- **Disk Usage Reports** - Comprehensive filesystem analysis
- **Process Monitoring** - Top 5 processes by CPU and memory consumption
- **System Information** - OS version, kernel, architecture, uptime
- **User Activity** - Currently logged users and session details
- **Security Events** - Authentication logs and failed login attempts
- **Network Information** - Interface status and connection statistics *(Linux version)*

## ✨ Features

### ✅ Core Requirements Met
- ✅ Total CPU Usage - percentage across all cores
- ✅ Total Memory Usage - free vs. used with percentage calculation
- ✅ Total Disk Usage - free vs. used with percentage calculation  
- ✅ Top 5 Processes by CPU Usage - sorted list with PID, name, and CPU%
- ✅ Top 5 Processes by Memory Usage - sorted list with PID, name, and memory%

### 🎯 Enhanced Features
- ✅ OS version and kernel information
- ✅ System uptime and load average
- ✅ Currently logged-in users
- ✅ Failed login attempts and security events
- ✅ Network interface statistics *(Linux version)*
- ✅ Colorized output for enhanced readability
- ✅ Cross-platform compatibility detection
- ✅ Error handling and prerequisite checking

## 📜 Scripts

### 1. `server-stats.sh` - Cross-Platform Version
**Compatibility:** Linux, macOS, and other Unix-like systems
```bash
./server-stats.sh
```
- Intelligent OS detection with platform-specific optimizations
- Graceful fallbacks for missing utilities
- Works on both development and production environments

### 2. `server-stats-linux.sh` - Production Linux Optimized
**Compatibility:** Linux distributions only (Ubuntu, CentOS, RHEL, Debian, etc.)
```bash
./server-stats-linux.sh
```
- Production-ready with enhanced error handling
- Advanced CPU monitoring using `/proc/stat` with 1-second sampling
- Detailed memory analysis including buffers, cache, and swap
- Network interface monitoring and connection statistics
- Enhanced security event logging
- Optimized performance for server environments

## 🚀 Installation

### Quick Setup
```bash
# Clone or download the scripts
git clone <your-repository-url>
cd server-stats

# Make scripts executable
chmod +x server-stats.sh
chmod +x server-stats-linux.sh

# Run the appropriate script
./server-stats.sh          # Cross-platform version
./server-stats-linux.sh    # Linux optimized version
```

### Manual Installation
```bash
# Download individual scripts
wget <script-url>/server-stats.sh
wget <script-url>/server-stats-linux.sh

# Set permissions
chmod +x *.sh
```

## 💻 Usage

### Basic Execution
```bash
# Cross-platform version (works on macOS, Linux)
./server-stats.sh

# Linux production version (Linux only)
./server-stats-linux.sh
```

### Advanced Usage
```bash
# Run with output redirection
./server-stats-linux.sh > server-report-$(date +%Y%m%d).txt

# Run as cron job (every hour)
0 * * * * /path/to/server-stats-linux.sh >> /var/log/server-stats.log

# Run with specific shell
bash ./server-stats.sh
```

## 📊 Output Examples

### System Information Section
```
SYSTEM INFORMATION
--------------------------------------------------------------------------------
Operating System:              Ubuntu 22.04.3 LTS
OS Version:                    22.04.3 LTS (Jammy Jellyfish)
Kernel Version:                5.15.0-88-generic
Architecture:                  x86_64
System Uptime:                 up 7 days, 14 hours, 23 minutes
Last Boot:                     2024-08-28 09:15
```

### CPU Usage Section
```
CPU USAGE STATISTICS
--------------------------------------------------------------------------------
Total CPU Usage:               23.4%
User CPU Usage:               15.2%
System CPU Usage:              5.1%
I/O Wait:                      3.1%
CPU Cores:                        8
CPU Model:                     Intel(R) Xeon(R) CPU E3-1270 v6 @ 3.80GHz
Load Average (1/5/15min):      1.45 / 1.23 / 0.98
```

### Memory Usage Section
```
MEMORY USAGE STATISTICS
--------------------------------------------------------------------------------
Total Memory:                  15.64 GB
Used Memory:                    8.23 GB ( 52.6%)
Available Memory:               7.41 GB ( 47.4%)
Buffers:                        0.58 GB
Cached:                         3.21 GB
Shared:                         0.12 GB

Total Swap:                     2.00 GB
Used Swap:                      0.00 GB (  0.0%)
Free Swap:                      2.00 GB
```

### Process Monitoring Section
```
TOP 5 PROCESSES BY CPU USAGE
--------------------------------------------------------------------------------
PID      USER             CPU%     MEM%     COMMAND
--------------------------------------------------------------------------------
1234     www-data         25.3     2.1      /usr/sbin/apache2 -DFOREGROUND
5678     mysql            18.7     12.4     /usr/sbin/mysqld --defaults-file=/etc/m
9101     root             8.2      0.5      [kworker/u16:2-events_unbound]
1121     ubuntu           5.1      1.8      /usr/bin/python3 /home/ubuntu/app.py
3141     root             2.9      0.3      /usr/sbin/sshd -D
```

## ⚙️ System Requirements

### Minimum Requirements
- **Operating System:** Linux (any modern distribution) or macOS
- **Shell:** Bash 4.0 or higher
- **RAM:** Minimal (script uses <1MB)
- **Permissions:** Read access to `/proc` filesystem (Linux), basic user permissions

### Required System Utilities
The following standard utilities must be available:
- `ps` - Process information
- `df` - Disk space usage
- `top` - System processes (Linux) / Activity monitor
- `uptime` - System uptime and load
- `who` - Logged-in users
- `awk` - Text processing
- `grep` - Text searching
- `sed` - Stream editing

### Optional Utilities (Enhanced Features)
- `bc` - Arbitrary precision calculator (fallback: `awk`)
- `nproc` - Number of CPU cores (fallback: `/proc/cpuinfo`)
- `vmstat` - Virtual memory statistics (Linux)
- `ss` - Socket statistics (Linux networking)
- `ip` - Network interface configuration (Linux)

### Supported Operating Systems
| OS | Cross-Platform Script | Linux Optimized Script |
|----|----------------------|----------------------|
| Ubuntu 18.04+ | ✅ | ✅ |
| CentOS 7+ | ✅ | ✅ |
| RHEL 7+ | ✅ | ✅ |
| Debian 9+ | ✅ | ✅ |
| Amazon Linux | ✅ | ✅ |
| macOS 10.14+ | ✅ | ❌ |
| FreeBSD | ⚠️ Limited | ❌ |

## 🔧 Troubleshooting

### Common Issues

#### Permission Denied Errors
```bash
# Make scripts executable
chmod +x server-stats.sh
chmod +x server-stats-linux.sh

# Check file permissions
ls -la *.sh
```

#### Missing Dependencies
```bash
# Check for required utilities
which ps df top uptime who awk grep sed

# On minimal systems, install missing packages
# Ubuntu/Debian
sudo apt-get install procps coreutils

# CentOS/RHEL
sudo yum install procps-ng coreutils
```

#### Authentication Log Access
```bash
# Grant read access to authentication logs (if needed)
sudo chmod +r /var/log/auth.log
sudo chmod +r /var/log/secure

# Alternative: Run with sudo for full system access
sudo ./server-stats-linux.sh
```

#### Cross-Platform Compatibility
```bash
# Check OS type
echo $OSTYPE

# Force Linux script check
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ./server-stats-linux.sh
else
    ./server-stats.sh
fi
```

### Performance Considerations

#### For High-Load Systems
- The Linux optimized script uses a 1-second sleep for CPU measurement
- On extremely busy systems, consider running during off-peak hours
- For continuous monitoring, implement proper log rotation

#### Memory Usage
- Both scripts have minimal memory footprint (<1MB)
- Safe to run on systems with limited RAM
- No persistent processes or background daemons

### Security Considerations

#### File Permissions
```bash
# Recommended permissions
chmod 755 server-stats*.sh  # Executable by owner, readable by others
chmod 644 README.md         # Readable by all

# For sensitive environments
chmod 700 server-stats*.sh  # Executable only by owner
```

#### Log Security
- Authentication logs may contain sensitive information
- Consider sanitizing output when sharing reports
- Implement proper log retention policies

## 🤝 Contributing

### Development Guidelines
1. **Cross-Platform Compatibility:** Test on multiple OS variants
2. **Error Handling:** Implement proper error checking and graceful fallbacks
3. **Performance:** Keep script execution time under 5 seconds
4. **Documentation:** Update README for any new features
5. **Testing:** Verify functionality on target systems

### Feature Requests
- Network bandwidth monitoring
- Historical data collection
- JSON/XML output formats
- Integration with monitoring systems (Nagios, Zabbix)
- Email alerting capabilities

### Code Style
- Use consistent indentation (4 spaces)
- Add comments for complex logic
- Follow shell scripting best practices
- Validate with `shellcheck` when available

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues, questions, or contributions:
- **Author:** Rowjay
- **Repository:** [Your Repository URL]
- **Documentation:** This README file

---

**Last Updated:** September 2025  
**Script Version:** 1.0.0
