#!/bin/bash

################################################################################
# DISK I/O PERFORMANCE ANALYZER
# 
# Usage: bash disk-io-analyzer.sh [device] [duration]
# Example: bash disk-io-analyzer.sh sda 60
################################################################################

DEVICE=${1:-sda}
DURATION=${2:-30}

echo "Disk I/O Performance Analysis"
echo "Device: $DEVICE"
echo "Duration: $DURATION seconds"
echo ""

if ! command -v iostat &> /dev/null; then
    echo "Error: iostat not found. Install sysstat package:"
    echo "  Ubuntu/Debian: sudo apt-get install sysstat"
    echo "  RHEL/CentOS: sudo yum install sysstat"
    exit 1
fi

echo "Collecting I/O metrics..."
echo ""

# Calculate number of iterations
INTERVAL=1
ITERATIONS=$((DURATION / INTERVAL))

iostat -x $INTERVAL $ITERATIONS $DEVICE 2>/dev/null | tail -$ITERATIONS | awk '
BEGIN {
    print "Time(s)    r/s      w/s      rMB/s    wMB/s    await    %util"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    count = 0
}
NF > 0 && NR > 1 {
    # iostat output: r/s w/s rMB/s wMB/s await %util
    printf "%-10d %-8.1f %-8.1f %-8.1f %-8.1f %-8.1f %-6.1f\n", \
        count * 1, $4, $5, $6, $7, $9, $12
    count++
}
'

echo ""
echo "=== I/O Analysis ==="

# Get summary statistics
DETAILS=$(iostat -x 1 2 $DEVICE 2>/dev/null | tail -1)
if [ -n "$DETAILS" ]; then
    echo "Final metrics:"
    echo "  Reads/sec: $(echo $DETAILS | awk '{print $4}') r/s"
    echo "  Writes/sec: $(echo $DETAILS | awk '{print $5}') w/s"
    echo "  Read MB/s: $(echo $DETAILS | awk '{print $6}') MB/s"
    echo "  Write MB/s: $(echo $DETAILS | awk '{print $7}') MB/s"
    echo "  Await (ms): $(echo $DETAILS | awk '{print $9}') ms"
    echo "  Utilization: $(echo $DETAILS | awk '{print $12}')%"
    
    AWAIT=$(echo $DETAILS | awk '{print $9}')
    UTIL=$(echo $DETAILS | awk '{print $12}')
    
    echo ""
    if (( $(echo "$AWAIT > 100" | bc -l 2>/dev/null || echo 0) )); then
        echo "⚠️  CRITICAL: High I/O latency (await > 100ms)"
    elif (( $(echo "$AWAIT > 50" | bc -l 2>/dev/null || echo 0) )); then
        echo "⚠️  HIGH: I/O latency elevated (await > 50ms)"
    else
        echo "✓ I/O latency normal"
    fi
    
    if (( $(echo "$UTIL > 90" | bc -l 2>/dev/null || echo 0) )); then
        echo "⚠️  CRITICAL: Disk is saturated (util > 90%)"
    elif (( $(echo "$UTIL > 80" | bc -l 2>/dev/null || echo 0) )); then
        echo "⚠️  HIGH: Disk utilization high (util > 80%)"
    else
        echo "✓ Disk utilization normal"
    fi
fi

echo ""
echo "RECOMMENDATIONS:"
echo "  1. If await > 50ms: Disk is I/O bottleneck"
echo "  2. If %util > 80%: Consider upgrading storage"
echo "  3. If high read/write: Check for unoptimized queries"
echo "  4. Monitor during peak load"
echo "  5. Use SSD for databases to reduce latency"
