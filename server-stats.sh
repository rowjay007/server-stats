#!/bin/bash

################################################################################
# SERVER STATS MONITORING SCRIPT
# Author: Rowjay
# Description: Comprehensive server performance monitoring and reporting tool
# Compatible with: Modern Linux distributions using standard system utilities
################################################################################

# Color codes for better output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Print header with timestamp
print_header() {
    echo -e "${WHITE}================================================================================================${NC}"
    echo -e "${WHITE}                                 SERVER PERFORMANCE REPORT${NC}"
    echo -e "${WHITE}================================================================================================${NC}"
    echo -e "${CYAN}Report Generated: $(date)${NC}"
    echo -e "${CYAN}Hostname: $(hostname)${NC}"
    echo ""
}

# Function to print section headers
print_section() {
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}$(printf '%.0s-' {1..80})${NC}"
}

# Function to get CPU usage
get_cpu_usage() {
    print_section "CPU USAGE STATISTICS"
    
    # Detect OS and use appropriate method
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux-specific CPU monitoring
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | sed 's/%//')
        if [ -z "$cpu_usage" ]; then
            # Alternative method using vmstat
            if command -v vmstat &> /dev/null; then
                cpu_usage=$(vmstat 1 2 | tail -1 | awk '{print 100-$15}')
            fi
        fi
        
        # If still empty, use /proc/stat method
        if [ -z "$cpu_usage" ] && [ -f "/proc/stat" ]; then
            cpu_line=$(head -n 1 /proc/stat)
            cpu_times=($cpu_line)
            idle_time=${cpu_times[4]}
            total_time=0
            for time in ${cpu_times[@]:1:8}; do
                total_time=$((total_time + time))
            done
            if command -v bc &> /dev/null; then
                cpu_usage=$(echo "scale=1; 100 - ($idle_time * 100 / $total_time)" | bc 2>/dev/null || echo "0.0")
            else
                cpu_usage=$(awk "BEGIN {printf \"%.1f\", 100 - ($idle_time * 100 / $total_time)}")
            fi
        fi
        
        # CPU cores information
        if command -v nproc &> /dev/null; then
            cpu_cores=$(nproc)
        else
            cpu_cores=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "N/A")
        fi
    else
        # macOS/BSD-specific CPU monitoring
        cpu_usage=$(top -l 1 -s 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
        if [ -z "$cpu_usage" ]; then
            cpu_usage="N/A"
        fi
        cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "N/A")
    fi
    
    printf "${GREEN}%-30s${NC} %6s%%\n" "Total CPU Usage:" "$cpu_usage"
    printf "${GREEN}%-30s${NC} %6s\n" "CPU Cores:" "$cpu_cores"
    
    # Load average (works on both Linux and macOS)
    load_avg=$(uptime | awk -F'load average' '{print $2}' | sed 's/^[: ]*//')
    printf "${GREEN}%-30s${NC} %s\n" "Load Average:" "$load_avg"
    echo ""
}

# Function to get memory usage
get_memory_usage() {
    print_section "MEMORY USAGE STATISTICS"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -f "/proc/meminfo" ]; then
        # Linux-specific memory monitoring
        while IFS=':' read -r key value; do
            case $key in
                MemTotal) mem_total=$(echo $value | awk '{print $1}') ;;
                MemFree) mem_free=$(echo $value | awk '{print $1}') ;;
                MemAvailable) mem_available=$(echo $value | awk '{print $1}') ;;
                Buffers) mem_buffers=$(echo $value | awk '{print $1}') ;;
                Cached) mem_cached=$(echo $value | awk '{print $1}') ;;
            esac
        done < /proc/meminfo
        
        # Calculate memory usage
        mem_used=$((mem_total - mem_available))
        
        # Use awk for calculations if bc is not available
        if command -v bc &> /dev/null; then
            mem_usage_percent=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc)
            mem_free_percent=$(echo "scale=1; $mem_available * 100 / $mem_total" | bc)
            mem_total_gb=$(echo "scale=2; $mem_total / 1024 / 1024" | bc)
            mem_used_gb=$(echo "scale=2; $mem_used / 1024 / 1024" | bc)
            mem_available_gb=$(echo "scale=2; $mem_available / 1024 / 1024" | bc)
        else
            mem_usage_percent=$(awk "BEGIN {printf \"%.1f\", $mem_used * 100 / $mem_total}")
            mem_free_percent=$(awk "BEGIN {printf \"%.1f\", $mem_available * 100 / $mem_total}")
            mem_total_gb=$(awk "BEGIN {printf \"%.2f\", $mem_total / 1024 / 1024}")
            mem_used_gb=$(awk "BEGIN {printf \"%.2f\", $mem_used / 1024 / 1024}")
            mem_available_gb=$(awk "BEGIN {printf \"%.2f\", $mem_available / 1024 / 1024}")
        fi
    else
        # macOS/BSD-specific memory monitoring
        if command -v vm_stat &> /dev/null; then
            page_size=$(vm_stat | grep "page size" | awk '{print $8}')
            pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
            pages_active=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
            pages_inactive=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
            pages_speculative=$(vm_stat | grep "Pages speculative" | awk '{print $3}' | sed 's/\.//' || echo 0)
            pages_wired=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
            
            mem_total_bytes=$(( (pages_free + pages_active + pages_inactive + pages_speculative + pages_wired) * page_size ))
            mem_used_bytes=$(( (pages_active + pages_inactive + pages_wired) * page_size ))
            mem_free_bytes=$(( (pages_free + pages_speculative) * page_size ))
            
            mem_total_gb=$(awk "BEGIN {printf \"%.2f\", $mem_total_bytes / 1024 / 1024 / 1024}")
            mem_used_gb=$(awk "BEGIN {printf \"%.2f\", $mem_used_bytes / 1024 / 1024 / 1024}")
            mem_available_gb=$(awk "BEGIN {printf \"%.2f\", $mem_free_bytes / 1024 / 1024 / 1024}")
            mem_usage_percent=$(awk "BEGIN {printf \"%.1f\", $mem_used_bytes * 100 / $mem_total_bytes}")
            mem_free_percent=$(awk "BEGIN {printf \"%.1f\", $mem_free_bytes * 100 / $mem_total_bytes}")
        else
            mem_total_gb="N/A"
            mem_used_gb="N/A"
            mem_available_gb="N/A"
            mem_usage_percent="N/A"
            mem_free_percent="N/A"
        fi
    fi
    
    printf "${GREEN}%-30s${NC} %6s GB\n" "Total Memory:" "$mem_total_gb"
    printf "${GREEN}%-30s${NC} %6s GB (%5s%%)\n" "Used Memory:" "$mem_used_gb" "$mem_usage_percent"
    printf "${GREEN}%-30s${NC} %6s GB (%5s%%)\n" "Available Memory:" "$mem_available_gb" "$mem_free_percent"
    echo ""
}

# Function to get disk usage
get_disk_usage() {
    print_section "DISK USAGE STATISTICS"
    
    printf "${GREEN}%-15s %-10s %-10s %-10s %-8s %-s${NC}\n" "Filesystem" "Size" "Used" "Available" "Use%" "Mounted on"
    printf "${GREEN}%.0s-${NC}" {1..80}
    echo ""
    
    # Get disk usage for all mounted filesystems, exclude special filesystems
    df -h | grep -E '^/dev/' | while read filesystem size used avail percent mountpoint; do
        printf "%-15s %-10s %-10s %-10s %-8s %-s\n" "$filesystem" "$size" "$used" "$avail" "$percent" "$mountpoint"
    done
    echo ""
}

# Function to get top processes by CPU usage
get_top_cpu_processes() {
    print_section "TOP 5 PROCESSES BY CPU USAGE"
    
    printf "${GREEN}%-8s %-20s %-8s %-s${NC}\n" "PID" "PROCESS NAME" "CPU%" "COMMAND"
    printf "${GREEN}%.0s-${NC}" {1..80}
    echo ""
    
    # Get top 5 processes by CPU usage - OS specific
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux version
        ps -eo pid,comm,%cpu,cmd --sort=-%cpu 2>/dev/null | head -6 | tail -5 | while read pid comm cpu cmd; do
            # Truncate process name and command for better formatting
            comm_short=$(echo "$comm" | cut -c1-20)
            cmd_short=$(echo "$cmd" | cut -c1-40)
            printf "%-8s %-20s %-8s %-s\n" "$pid" "$comm_short" "$cpu" "$cmd_short"
        done
    else
        # macOS/BSD version
        ps -eo pid,comm,pcpu,command | sort -k3 -nr | head -5 | while read pid comm cpu cmd; do
            # Truncate process name and command for better formatting
            comm_short=$(echo "$comm" | cut -c1-20)
            cmd_short=$(echo "$cmd" | cut -c1-40)
            printf "%-8s %-20s %-8s %-s\n" "$pid" "$comm_short" "$cpu" "$cmd_short"
        done
    fi
    echo ""
}

# Function to get top processes by memory usage
get_top_memory_processes() {
    print_section "TOP 5 PROCESSES BY MEMORY USAGE"
    
    printf "${GREEN}%-8s %-20s %-8s %-s${NC}\n" "PID" "PROCESS NAME" "MEM%" "COMMAND"
    printf "${GREEN}%.0s-${NC}" {1..80}
    echo ""
    
    # Get top 5 processes by memory usage - OS specific
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux version
        ps -eo pid,comm,%mem,cmd --sort=-%mem 2>/dev/null | head -6 | tail -5 | while read pid comm mem cmd; do
            # Truncate process name and command for better formatting
            comm_short=$(echo "$comm" | cut -c1-20)
            cmd_short=$(echo "$cmd" | cut -c1-40)
            printf "%-8s %-20s %-8s %-s\n" "$pid" "$comm_short" "$mem" "$cmd_short"
        done
    else
        # macOS/BSD version
        ps -eo pid,comm,pmem,command | sort -k3 -nr | head -5 | while read pid comm mem cmd; do
            # Truncate process name and command for better formatting
            comm_short=$(echo "$comm" | cut -c1-20)
            cmd_short=$(echo "$cmd" | cut -c1-40)
            printf "%-8s %-20s %-8s %-s\n" "$pid" "$comm_short" "$mem" "$cmd_short"
        done
    fi
    echo ""
}

# Function to get system information (stretch goals)
get_system_info() {
    print_section "SYSTEM INFORMATION"
    
    # OS Version and Kernel
    if [ -f /etc/os-release ]; then
        os_name=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'"' -f2)
    else
        os_name=$(uname -s)
    fi
    kernel_version=$(uname -r)
    architecture=$(uname -m)
    
    printf "${GREEN}%-30s${NC} %s\n" "Operating System:" "$os_name"
    printf "${GREEN}%-30s${NC} %s\n" "Kernel Version:" "$kernel_version"
    printf "${GREEN}%-30s${NC} %s\n" "Architecture:" "$architecture"
    
    # System uptime
    uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    printf "${GREEN}%-30s${NC} %s\n" "System Uptime:" "$uptime_info"
    echo ""
}

# Function to get user information
get_user_info() {
    print_section "USER ACTIVITY"
    
    # Currently logged in users
    echo -e "${GREEN}Currently Logged In Users:${NC}"
    who | awk '{printf "%-15s %-15s %s %s\n", $1, $2, $3, $4}' | sort -u
    echo ""
    
    # User count
    user_count=$(who | wc -l)
    printf "${GREEN}%-30s${NC} %d\n" "Active User Sessions:" "$user_count"
    echo ""
}

# Function to get security information
get_security_info() {
    print_section "SECURITY INFORMATION"
    
    # Last login attempts
    echo -e "${GREEN}Recent Login Attempts:${NC}"
    if [ -f /var/log/auth.log ]; then
        tail -n 10 /var/log/auth.log 2>/dev/null | grep -E "(Failed|Accepted)" | tail -5
    elif [ -f /var/log/secure ]; then
        tail -n 10 /var/log/secure 2>/dev/null | grep -E "(Failed|Accepted)" | tail -5
    else
        echo "Authentication log not accessible or not found"
    fi
    echo ""
    
    # Failed login attempts count (last 24 hours)
    if [ -f /var/log/auth.log ]; then
        failed_logins=$(grep "$(date +'%b %d')" /var/log/auth.log 2>/dev/null | grep -c "Failed password" || echo "0")
    elif [ -f /var/log/secure ]; then
        failed_logins=$(grep "$(date +'%b %d')" /var/log/secure 2>/dev/null | grep -c "Failed password" || echo "0")
    else
        failed_logins="N/A"
    fi
    printf "${GREEN}%-30s${NC} %s\n" "Failed Logins Today:" "$failed_logins"
    echo ""
}

# Function to print footer
print_footer() {
    echo -e "${WHITE}================================================================================================${NC}"
    echo -e "${WHITE}                              END OF SERVER PERFORMANCE REPORT${NC}"
    echo -e "${WHITE}================================================================================================${NC}"
}

# Main execution
main() {
    # Check if running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo -e "${RED}Warning: This script is optimized for Linux systems.${NC}"
        echo -e "${RED}Some features may not work correctly on other operating systems.${NC}"
        echo ""
    fi
    
    # Check for required utilities
    required_commands=("ps" "df" "top" "uptime" "who")
    missing_commands=()
    
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
    print_footer
}

# Execute main function
main "$@"
