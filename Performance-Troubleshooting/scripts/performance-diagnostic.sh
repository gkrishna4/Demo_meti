#!/bin/bash

################################################################################
# COMPREHENSIVE PERFORMANCE DIAGNOSTIC SCRIPT
# 
# Usage: bash performance-diagnostic.sh [output_file]
# Example: bash performance-diagnostic.sh performance-report.txt
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output file
OUTPUT_FILE="${1:-/tmp/performance-diagnostic-$(date +%Y%m%d-%H%M%S).txt}"

# Function to print colored output
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "\n${YELLOW}▶ $1${NC}"
}

print_ok() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${RED}⚠️ $1${NC}"
}

# Redirect output to file and console
exec 1> >(tee -a "$OUTPUT_FILE")
exec 2>&1

echo "Performance Diagnostic Report"
echo "Generated: $(date)"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Output saved to: $OUTPUT_FILE"

print_header "SYSTEM PERFORMANCE DIAGNOSTIC"

# ============================================================================
# 1. SYSTEM OVERVIEW
# ============================================================================

print_section "System Uptime and Load"
uptime
echo ""
echo "CPU Cores: $(nproc)"
echo "CPU Model: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"

# ============================================================================
# 2. LOAD AVERAGE ANALYSIS
# ============================================================================

print_section "Load Average Analysis"
LOAD=$(cat /proc/loadavg | awk '{print $1}')
CORES=$(nproc)
RATIO=$(echo "scale=2; $LOAD / $CORES" | bc 2>/dev/null || echo "N/A")

echo "1-minute load: $LOAD"
echo "CPU Cores: $CORES"
echo "Load/Core Ratio: $RATIO"

if (( $(echo "$LOAD > $CORES * 1.5" | bc -l 2>/dev/null || echo 0) )); then
    print_warning "High load average detected"
else
    print_ok "Load average is normal"
fi

# ============================================================================
# 3. CPU ANALYSIS
# ============================================================================

print_section "CPU Performance"
echo "Current CPU Usage:"
top -bn1 | grep 'Cpu(s)' | awk '{print $2, $4, $6, $8, $10}'

echo ""
echo "Top 5 CPU Consuming Processes:"
ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "PID:%6s CPU:%6.1f%% MEM:%6.1f%% CMD:%s\n", $2, $3, $4, $11}'

# ============================================================================
# 4. MEMORY ANALYSIS
# ============================================================================

print_section "Memory Performance"
free -h

echo ""
MEM_USED=$(free | grep Mem | awk '{printf("%.2f", ($3/$2)*100)}')
echo "Memory Usage: ${MEM_USED}%"

if (( $(echo "$MEM_USED > 85" | bc -l 2>/dev/null || echo 0) )); then
    print_warning "High memory usage detected"
else
    print_ok "Memory usage is normal"
fi

echo ""
echo "Top 5 Memory Consuming Processes:"
ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "PID:%6s MEM:%6.1f%% RSS:%7s CMD:%s\n", $2, $4, $6, $11}'

# ============================================================================
# 5. DISK SPACE ANALYSIS
# ============================================================================

print_section "Disk Space Usage"
df -h | grep -v '^Filesystem\|tmpfs\|cdrom'

echo ""
echo "Top 10 Directories by Size:"
du -sh /* 2>/dev/null | sort -rh | head -10

# Check for critical disk usage
echo ""
echo "Checking for full partitions..."
FULL_PARTS=$(df -h | awk 'NR>1 && !/tmpfs/ {gsub("%",""); if($5>=90) print $1 ":" $5 "%"}')
if [ -n "$FULL_PARTS" ]; then
    print_warning "Critical disk usage detected:"
    echo "$FULL_PARTS"
else
    print_ok "All partitions have adequate space"
fi

# ============================================================================
# 6. DISK I/O ANALYSIS
# ============================================================================

print_section "Disk I/O Performance"
if command -v iostat &> /dev/null; then
    iostat -x 1 3 2>/dev/null | tail -20
else
    echo "iostat not available (install sysstat package)"
    vmstat 1 3
fi

# ============================================================================
# 7. NETWORK ANALYSIS
# ============================================================================

print_section "Network Performance"
echo "Network Interfaces:"
ip -s link | grep -A1 'link/ether' | head -6

echo ""
echo "TCP Connection Summary:"
echo "  ESTABLISHED: $(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l || echo 'N/A')"
echo "  TIME_WAIT: $(netstat -an 2>/dev/null | grep TIME_WAIT | wc -l || echo 'N/A')"
echo "  CLOSE_WAIT: $(netstat -an 2>/dev/null | grep CLOSE_WAIT | wc -l || echo 'N/A')"

# ============================================================================
# 8. PROCESS ANALYSIS
# ============================================================================

print_section "Process Information"
echo "Total Processes: $(ps aux | wc -l)"
echo "Running Processes: $(ps aux | grep -v defunct | wc -l)"
echo "Zombie Processes: $(ps aux | grep defunct | wc -l)"

echo ""
echo "Top 10 Processes by Elapsed Time:"
ps auxww --sort=etime | tail -11 | head -10 | awk '{printf "PID:%6s TIME:%15s CMD:%s\n", $2, $15, $11}'

# ============================================================================
# 9. SYSTEM SERVICES
# ============================================================================

print_section "System Services"
echo "Failed Services:"
systemctl --failed --no-pager 2>/dev/null | grep -E 'failed|FAILED' || echo "None - All services healthy"

echo ""
echo "Key Services Status:"
for service in sshd mysql httpd nginx docker; do
    if systemctl list-unit-files $service.service &>/dev/null; then
        STATUS=$(systemctl is-active $service 2>/dev/null)
        if [ "$STATUS" = "active" ]; then
            print_ok "$service: $STATUS"
        else
            print_warning "$service: $STATUS"
        fi
    fi
done

# ============================================================================
# 10. SYSTEM LOGS
# ============================================================================

print_section "Recent System Errors"
echo "Last 10 system errors:"
journalctl -p err -n 10 --no-pager 2>/dev/null || tail -10 /var/log/syslog 2>/dev/null || tail -10 /var/log/messages 2>/dev/null || echo "No recent errors"

# ============================================================================
# 11. INODE USAGE
# ============================================================================

print_section "Inode Usage"
df -i | grep -v '^Filesystem'

# ============================================================================
# 12. OPEN FILES
# ============================================================================

print_section "Open Files"
echo "Total open file descriptors: $(lsof 2>/dev/null | wc -l || echo 'N/A (lsof not available)')"
echo "Max file descriptors: $(cat /proc/sys/fs/file-max 2>/dev/null || echo 'N/A')"

if [ -f /proc/sys/fs/file-nr ]; then
    USED=$(awk '{print $1}' /proc/sys/fs/file-nr)
    MAX=$(awk '{print $3}' /proc/sys/fs/file-nr)
    PERCENT=$((USED * 100 / MAX))
    echo "File descriptor usage: $USED/$MAX ($PERCENT%)"
fi

# ============================================================================
# 13. SWAP ANALYSIS
# ============================================================================

print_section "Swap Usage"
swapon -s 2>/dev/null || echo "No swap configured"

SWAP_USED=$(free | grep Swap | awk '{printf("%.2f", ($3/$2)*100)}')
if [ "$SWAP_USED" != "" ]; then
    echo ""
    echo "Swap Usage: ${SWAP_USED}%"
    if (( $(echo "$SWAP_USED > 10" | bc -l 2>/dev/null || echo 0) )); then
        print_warning "System using swap - may indicate memory pressure"
    fi
fi

# ============================================================================
# 14. SUMMARY AND RECOMMENDATIONS
# ============================================================================

print_header "SUMMARY AND RECOMMENDATIONS"

echo "Diagnostic checks completed successfully."
echo "Report saved to: $OUTPUT_FILE"
echo ""
echo "KEY METRICS TO MONITOR:"
echo "  1. Load Average: Should be <= CPU cores"
echo "  2. Memory Usage: Should stay < 85%"
echo "  3. Disk Usage: Should stay < 85%"
echo "  4. I/O Wait: Should be < 20%"
echo "  5. Swap Usage: Should be 0% ideally"
echo ""
echo "NEXT STEPS:"
echo "  1. Review the full report above"
echo "  2. If issues found, use specific troubleshooting playbooks"
echo "  3. Set up continuous monitoring for trend analysis"
echo "  4. Archive this report for historical comparison"
echo ""
print_ok "Diagnostic complete"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Report saved to: $OUTPUT_FILE"
echo "═══════════════════════════════════════════════════════"
