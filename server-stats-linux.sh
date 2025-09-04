#!/bin/bash

################################################################################
# SERVER STATS MONITORING SCRIPT - LINUX OPTIMIZED
# Author: Rowjay
# Description: Production-ready server performance monitoring for Linux systems
# Compatible with: All modern Linux distributions
# Dependencies: Only standard Linux utilities (ps, df, top, uptime, who)
################################################################################

# Color codes for enhanced output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Script metadata
readonly SCRIPT_NAME="Linux Server Statistics Monitor"
readonly SCRIPT_VERSION="1.0.0"
readonly AUTHOR="Rowjay"

# Print header with timestamp and system info
print_header() {
    echo -e "${WHITE}================================================================================================${NC}"
    echo -e "${WHITE}                           ${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}"
    echo -e "${WHITE}================================================================================================${NC}"
    echo -e "${CYAN}Report Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
    echo -e "${CYAN}Hostname: $(hostname -f 2>/dev/null || hostname)${NC}"
    echo -e "${CYAN}Server IP: $(hostname -I 2>/dev/null | awk '{print $1}' || echo 'N/A')${NC}"
    echo ""
}

# Function to print section headers
print_section() {
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}$(printf '%.0s-' {1..80})${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    local required_commands=("ps" "df" "top" "uptime" "who" "awk" "grep" "sed")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        echo -e "${RED}Error: The following required commands are missing:${NC}"
        printf "${RED}%s ${NC}" "${missing_commands[@]}"
        echo ""
        echo -e "${RED}Please install the missing utilities and try again.${NC}"
        exit 1
    fi
    
    # Verify we're running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo -e "${RED}Error: This script is designed specifically for Linux systems.${NC}"
        echo -e "${RED}Current OS: $OSTYPE${NC}"
        exit 1
    fi
}

# Function to get comprehensive CPU usage statistics
get_cpu_usage() {
    print_section "CPU USAGE STATISTICS"
    
    # Method 1: Parse /proc/stat for most accurate CPU usage
    if [ -f "/proc/stat" ]; then
        # Read CPU stats twice with 1 second interval for accurate measurement
        cpu_stats1=$(head -n 1 /proc/stat)
        sleep 1
        cpu_stats2=$(head -n 1 /proc/stat)
        
        # Parse first reading
        read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 guest1 guest_nice1 <<< "$cpu_stats1"
        # Parse second reading  
        read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 guest2 guest_nice2 <<< "$cpu_stats2"
        
        # Calculate differences
        user_diff=$((user2 - user1))
        nice_diff=$((nice2 - nice1))
        system_diff=$((system2 - system1))
        idle_diff=$((idle2 - idle1))
        iowait_diff=$((iowait2 - iowait1))
        irq_diff=$((irq2 - irq1))
        softirq_diff=$((softirq2 - softirq1))
        steal_diff=$((steal2 - steal1))
        
        total_diff=$((user_diff + nice_diff + system_diff + idle_diff + iowait_diff + irq_diff + softirq_diff + steal_diff))
        
        if [ "$total_diff" -gt 0 ]; then
            cpu_usage=$(awk "BEGIN {printf \"%.1f\", 100 - ($idle_diff * 100 / $total_diff)}")
            user_usage=$(awk "BEGIN {printf \"%.1f\", $user_diff * 100 / $total_diff}")
            system_usage=$(awk "BEGIN {printf \"%.1f\", $system_diff * 100 / $total_diff}")
            iowait_usage=$(awk "BEGIN {printf \"%.1f\", $iowait_diff * 100 / $total_diff}")
        else
            cpu_usage="0.0"
            user_usage="0.0" 
            system_usage="0.0"
            iowait_usage="0.0"
        fi
    else
        # Fallback method using top
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | sed 's/%//' || echo "N/A")
        user_usage="N/A"
        system_usage="N/A"
        iowait_usage="N/A"
    fi
    
    # Get CPU information
    if command -v nproc &> /dev/null; then
        cpu_cores=$(nproc)
    else
        cpu_cores=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "N/A")
    fi
    
    # Get CPU model information
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^ *//' || echo "Unknown")
    
    # Get load averages
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    read -r load1 load5 load15 <<< $(echo $load_avg | tr ',' ' ')
    
    # Display CPU statistics
    printf "${GREEN}%-30s${NC} %6s%%\n" "Total CPU Usage:" "$cpu_usage"
    printf "${GREEN}%-30s${NC} %6s%%\n" "User CPU Usage:" "$user_usage"
    printf "${GREEN}%-30s${NC} %6s%%\n" "System CPU Usage:" "$system_usage"
    printf "${GREEN}%-30s${NC} %6s%%\n" "I/O Wait:" "$iowait_usage"
    printf "${GREEN}%-30s${NC} %6s\n" "CPU Cores:" "$cpu_cores"
    printf "${GREEN}%-30s${NC} %s\n" "CPU Model:" "$cpu_model"
    printf "${GREEN}%-30s${NC} %s / %s / %s\n" "Load Average (1/5/15min):" "$load1" "$load5" "$load15"
    echo ""
}

# Function to get detailed memory usage statistics
get_memory_usage() {
    print_section "MEMORY USAGE STATISTICS"
    
    if [ -f "/proc/meminfo" ]; then
        # Parse /proc/meminfo for detailed memory statistics
        while IFS=':' read -r key value; do
            case $key in
                MemTotal) mem_total=$(echo $value | awk '{print $1}') ;;
                MemFree) mem_free=$(echo $value | awk '{print $1}') ;;
                MemAvailable) mem_available=$(echo $value | awk '{print $1}') ;;
                Buffers) mem_buffers=$(echo $value | awk '{print $1}') ;;
                Cached) mem_cached=$(echo $value | awk '{print $1}') ;;
                SwapTotal) swap_total=$(echo $value | awk '{print $1}') ;;
                SwapFree) swap_free=$(echo $value | awk '{print $1}') ;;
                Shmem) mem_shared=$(echo $value | awk '{print $1}') ;;
            esac
        done < /proc/meminfo
        
        # Calculate memory statistics
        mem_used=$((mem_total - mem_available))
        swap_used=$((swap_total - swap_free))
        
        # Calculate percentages and convert to GB
        mem_usage_percent=$(awk "BEGIN {printf \"%.1f\", $mem_used * 100 / $mem_total}")
        mem_free_percent=$(awk "BEGIN {printf \"%.1f\", $mem_available * 100 / $mem_total}")
        
        mem_total_gb=$(awk "BEGIN {printf \"%.2f\", $mem_total / 1024 / 1024}")
        mem_used_gb=$(awk "BEGIN {printf \"%.2f\", $mem_used / 1024 / 1024}")
        mem_available_gb=$(awk "BEGIN {printf \"%.2f\", $mem_available / 1024 / 1024}")
        mem_buffers_gb=$(awk "BEGIN {printf \"%.2f\", $mem_buffers / 1024 / 1024}")
        mem_cached_gb=$(awk "BEGIN {printf \"%.2f\", $mem_cached / 1024 / 1024}")
        mem_shared_gb=$(awk "BEGIN {printf \"%.2f\", $mem_shared / 1024 / 1024}")
        
        # Swap statistics
        if [ "$swap_total" -gt 0 ]; then
            swap_usage_percent=$(awk "BEGIN {printf \"%.1f\", $swap_used * 100 / $swap_total}")
            swap_total_gb=$(awk "BEGIN {printf \"%.2f\", $swap_total / 1024 / 1024}")
            swap_used_gb=$(awk "BEGIN {printf \"%.2f\", $swap_used / 1024 / 1024}")
            swap_free_gb=$(awk "BEGIN {printf \"%.2f\", $swap_free / 1024 / 1024}")
        else
            swap_usage_percent="0.0"
            swap_total_gb="0.00"
            swap_used_gb="0.00" 
            swap_free_gb="0.00"
        fi
        
        # Display memory statistics
        printf "${GREEN}%-30s${NC} %6.2f GB\n" "Total Memory:" "$mem_total_gb"
        printf "${GREEN}%-30s${NC} %6.2f GB (%5.1f%%)\n" "Used Memory:" "$mem_used_gb" "$mem_usage_percent"
        printf "${GREEN}%-30s${NC} %6.2f GB (%5.1f%%)\n" "Available Memory:" "$mem_available_gb" "$mem_free_percent"
        printf "${GREEN}%-30s${NC} %6.2f GB\n" "Buffers:" "$mem_buffers_gb"
        printf "${GREEN}%-30s${NC} %6.2f GB\n" "Cached:" "$mem_cached_gb"
        printf "${GREEN}%-30s${NC} %6.2f GB\n" "Shared:" "$mem_shared_gb"
        echo ""
        printf "${GREEN}%-30s${NC} %6.2f GB\n" "Total Swap:" "$swap_total_gb"
        printf "${GREEN}%-30s${NC} %6.2f GB (%5.1f%%)\n" "Used Swap:" "$swap_used_gb" "$swap_usage_percent"
        printf "${GREEN}%-30s${NC} %6.2f GB\n" "Free Swap:" "$swap_free_gb"
    else
        echo -e "${RED}Error: /proc/meminfo not accessible${NC}"
    fi
    echo ""
}

# Function to get comprehensive disk usage statistics
get_disk_usage() {
    print_section "DISK USAGE STATISTICS"
    
    printf "${GREEN}%-20s %-8s %-8s %-8s %-6s %-s${NC}\n" "Filesystem" "Size" "Used" "Avail" "Use%" "Mounted on"
    printf "${GREEN}%.0s-${NC}" {1..80}
    echo ""
    
    # Get disk usage for all mounted filesystems, exclude special filesystems
    df -h | grep -E '^/dev/' | while read filesystem size used avail percent mountpoint; do
        printf "%-20s %-8s %-8s %-8s %-6s %-s\n" "$filesystem" "$size" "$used" "$avail" "$percent" "$mountpoint"
    done
    
    echo ""
    
    # Additional disk statistics
    printf "${GREEN}%-30s${NC} %s\n" "Total Mounted Filesystems:" "$(df -h | grep -c '^/dev/')"
    
    # Show inodes usage for root filesystem
    root_inode_usage=$(df -i / | tail -1 | awk '{print $5}' | sed 's/%//')
    printf "${GREEN}%-30s${NC} %s%%\n" "Root Inode Usage:" "$root_inode_usage"
    echo ""
}

# Function to get top processes by CPU usage
get_top_cpu_processes() {
    print_section "TOP 5 PROCESSES BY CPU USAGE"
    
    printf "${GREEN}%-8s %-16s %-8s %-8s %-s${NC}\n" "PID" "USER" "CPU%" "MEM%" "COMMAND"
    printf "${GREEN}%.0s-${NC}" {1..80}
    echo ""
    
    # Get top 5 processes by CPU usage
    ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu | head -6 | tail -5 | while read pid user cpu mem cmd; do
        # Truncate user and command for better formatting
        user_short=$(echo "$user" | cut -c1-16)
        cmd_short=$(echo "$cmd" | cut -c1-45)
        printf "%-8s %-16s %-8s %-8s %-s\n" "$pid" "$user_short" "$cpu" "$mem" "$cmd_short"
    done
    echo ""
}

# Function to get top processes by memory usage
get_top_memory_processes() {
    print_section "TOP 5 PROCESSES BY MEMORY USAGE"
    
    printf "${GREEN}%-8s %-16s %-8s %-8s %-s${NC}\n" "PID" "USER" "MEM%" "CPU%" "COMMAND"
    printf "${GREEN}%.0s-${NC}" {1..80}
    echo ""
    
    # Get top 5 processes by memory usage
    ps -eo pid,user,%mem,%cpu,cmd --sort=-%mem | head -6 | tail -5 | while read pid user mem cpu cmd; do
        # Truncate user and command for better formatting
        user_short=$(echo "$user" | cut -c1-16)
        cmd_short=$(echo "$cmd" | cut -c1-45)
        printf "%-8s %-16s %-8s %-8s %-s\n" "$pid" "$user_short" "$mem" "$cpu" "$cmd_short"
    done
    echo ""
}

# Function to get system information
get_system_info() {
    print_section "SYSTEM INFORMATION"
    
    # OS Version and Kernel
    if [ -f /etc/os-release ]; then
        os_name=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'"' -f2)
        os_version=$(grep "^VERSION=" /etc/os-release | cut -d'"' -f2)
    else
        os_name="Linux"
        os_version="Unknown"
    fi
    
    kernel_version=$(uname -r)
    architecture=$(uname -m)
    
    # System uptime
    uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    
    # Boot time
    boot_time=$(who -b 2>/dev/null | awk '{print $3, $4}' || echo "Unknown")
    
    printf "${GREEN}%-30s${NC} %s\n" "Operating System:" "$os_name"
    printf "${GREEN}%-30s${NC} %s\n" "OS Version:" "$os_version"
    printf "${GREEN}%-30s${NC} %s\n" "Kernel Version:" "$kernel_version"
    printf "${GREEN}%-30s${NC} %s\n" "Architecture:" "$architecture"
    printf "${GREEN}%-30s${NC} %s\n" "System Uptime:" "$uptime_info"
    printf "${GREEN}%-30s${NC} %s\n" "Last Boot:" "$boot_time"
    echo ""
}

# Function to get user activity information
get_user_info() {
    print_section "USER ACTIVITY"
    
    echo -e "${GREEN}Currently Logged In Users:${NC}"
    printf "${GREEN}%-16s %-12s %-16s %-s${NC}\n" "USER" "TTY" "LOGIN TIME" "FROM"
    printf "${GREEN}%.0s-${NC}" {1..80}
    echo ""
    
    who | while read user tty datetime from; do
        # Handle cases where 'from' field might be empty
        from=${from:-"local"}
        printf "%-16s %-12s %-16s %-s\n" "$user" "$tty" "$datetime" "$from"
    done
    
    echo ""
    
    # User statistics
    user_count=$(who | wc -l)
    unique_users=$(who | awk '{print $1}' | sort -u | wc -l)
    root_sessions=$(who | grep -c '^root ' || echo 0)
    
    printf "${GREEN}%-30s${NC} %d\n" "Active User Sessions:" "$user_count"
    printf "${GREEN}%-30s${NC} %d\n" "Unique Users:" "$unique_users"
    printf "${GREEN}%-30s${NC} %d\n" "Root Sessions:" "$root_sessions"
    echo ""
}

# Function to get security and system events
get_security_info() {
    print_section "SECURITY INFORMATION"
    
    # Check for authentication logs
    auth_log=""
    if [ -r /var/log/auth.log ]; then
        auth_log="/var/log/auth.log"
    elif [ -r /var/log/secure ]; then
        auth_log="/var/log/secure"
    fi
    
    if [ -n "$auth_log" ]; then
        echo -e "${GREEN}Recent Authentication Events (Last 5):${NC}"
        tail -n 20 "$auth_log" 2>/dev/null | grep -E "(Failed|Accepted|sudo)" | tail -5 | while read line; do
            echo "  $line"
        done
        echo ""
        
        # Failed login attempts today
        today=$(date +'%b %d')
        failed_logins=$(grep "$today" "$auth_log" 2>/dev/null | grep -c "Failed password" || echo "0")
        successful_logins=$(grep "$today" "$auth_log" 2>/dev/null | grep -c "Accepted password" || echo "0")
        sudo_commands=$(grep "$today" "$auth_log" 2>/dev/null | grep -c "sudo:" || echo "0")
        
        printf "${GREEN}%-30s${NC} %s\n" "Failed Logins Today:" "$failed_logins"
        printf "${GREEN}%-30s${NC} %s\n" "Successful Logins Today:" "$successful_logins"
        printf "${GREEN}%-30s${NC} %s\n" "Sudo Commands Today:" "$sudo_commands"
    else
        echo "Authentication log not accessible"
        printf "${GREEN}%-30s${NC} %s\n" "Failed Logins Today:" "N/A"
        printf "${GREEN}%-30s${NC} %s\n" "Successful Logins Today:" "N/A"
        printf "${GREEN}%-30s${NC} %s\n" "Sudo Commands Today:" "N/A"
    fi
    
    echo ""
}

# Function to get network information (bonus feature)
get_network_info() {
    print_section "NETWORK INFORMATION"
    
    # Network interfaces
    echo -e "${GREEN}Active Network Interfaces:${NC}"
    ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -v '^lo$' | head -5 | while read interface; do
        ip_addr=$(ip addr show "$interface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -1)
        status=$(ip link show "$interface" 2>/dev/null | grep -o 'state [A-Z]*' | awk '{print $2}')
        printf "  %-16s %-16s %s\n" "$interface" "${ip_addr:-N/A}" "$status"
    done
    
    echo ""
    
    # Network connections count
    if command -v ss &> /dev/null; then
        tcp_connections=$(ss -tn 2>/dev/null | grep -c '^ESTAB' || echo "N/A")
        listening_ports=$(ss -tln 2>/dev/null | grep -c '^LISTEN' || echo "N/A")
    else
        tcp_connections="N/A"
        listening_ports="N/A"
    fi
    
    printf "${GREEN}%-30s${NC} %s\n" "TCP Connections:" "$tcp_connections"
    printf "${GREEN}%-30s${NC} %s\n" "Listening Ports:" "$listening_ports"
    echo ""
}

# Function to print footer
print_footer() {
    echo -e "${WHITE}================================================================================================${NC}"
    echo -e "${WHITE}                          END OF SERVER PERFORMANCE REPORT${NC}"
    echo -e "${WHITE}                              Generated by $AUTHOR${NC}"
    echo -e "${WHITE}================================================================================================${NC}"
}

# Main execution function
main() {
    # Check prerequisites first
    check_prerequisites
    
    # Execute all monitoring functions
    print_header
    get_system_info
    get_cpu_usage
    get_memory_usage
    get_disk_usage
    get_top_cpu_processes
    get_top_memory_processes
    get_user_info
    get_security_info
    get_network_info
    print_footer
}

# Script execution with error handling
set -euo pipefail

# Execute main function with all arguments
main "$@"
