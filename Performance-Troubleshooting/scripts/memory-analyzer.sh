#!/bin/bash

################################################################################
# MEMORY LEAK DETECTION AND ANALYSIS SCRIPT
# 
# Usage: bash memory-analyzer.sh <PID> [interval] [duration]
# Example: bash memory-analyzer.sh 12345 10 300  # Monitor PID 12345, every 10s for 5 mins
################################################################################

if [ $# -lt 1 ]; then
    echo "Usage: $0 <PID> [interval] [duration]"
    echo "Example: $0 12345 10 300"
    exit 1
fi

PID=$1
INTERVAL=${2:-10}
DURATION=${3:-300}

echo "Memory Analysis for PID: $PID"
echo "Interval: $INTERVAL seconds"
echo "Duration: $DURATION seconds"
echo "Total iterations: $((DURATION / INTERVAL))"
echo ""

echo "=== Process Information ==="
ps -p $PID -o pid,cmd,etime,%cpu,%mem,rss,vsz 2>/dev/null || {
    echo "Error: PID $PID not found"
    exit 1
}

echo ""
echo "=== Memory Monitoring ==="
echo "Time(s)    RSS(MB)    VSZ(MB)    Growth"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

INITIAL_RSS=$(ps -p $PID -o rss= 2>/dev/null)
TIME_ELAPSED=0

while [ $TIME_ELAPSED -lt $DURATION ]; do
    RSS=$(ps -p $PID -o rss= 2>/dev/null)
    VSZ=$(ps -p $PID -o vsz= 2>/dev/null)
    
    if [ -z "$RSS" ]; then
        echo "Process $PID no longer running"
        break
    fi
    
    RSS_MB=$(echo "scale=2; $RSS / 1024" | bc)
    VSZ_MB=$(echo "scale=2; $VSZ / 1024" | bc)
    GROWTH=$(echo "scale=2; ($RSS - $INITIAL_RSS) / 1024" | bc)
    
    printf "%-10d %-10s %-10s %-10s\n" "$TIME_ELAPSED" "$RSS_MB" "$VSZ_MB" "$GROWTH"
    
    sleep $INTERVAL
    TIME_ELAPSED=$((TIME_ELAPSED + INTERVAL))
done

echo ""
echo "=== Analysis ==="

FINAL_RSS=$(ps -p $PID -o rss= 2>/dev/null)
if [ -n "$FINAL_RSS" ]; then
    FINAL_GROWTH=$(echo "scale=2; ($FINAL_RSS - $INITIAL_RSS) / 1024" | bc)
    GROWTH_PERCENT=$(echo "scale=2; ($FINAL_RSS - $INITIAL_RSS) * 100 / $INITIAL_RSS" | bc)
    
    echo "Initial RSS: $(echo "scale=2; $INITIAL_RSS / 1024" | bc) MB"
    echo "Final RSS: $(echo "scale=2; $FINAL_RSS / 1024" | bc) MB"
    echo "Total Growth: $FINAL_GROWTH MB ($GROWTH_PERCENT%)"
    echo ""
    
    if (( $(echo "$FINAL_GROWTH > 50" | bc -l 2>/dev/null || echo 0) )); then
        echo "⚠️  MEMORY LEAK DETECTED: Significant memory growth"
        echo "Recommendation: Review application code for:"
        echo "  1. Unbounded caches or buffers"
        echo "  2. Object accumulation without cleanup"
        echo "  3. Resource leaks (file handles, connections)"
    elif (( $(echo "$FINAL_GROWTH > 10" | bc -l 2>/dev/null || echo 0) )); then
        echo "⚠️  Possible memory leak: Monitor further"
    else
        echo "✓ Memory usage stable - No leak detected"
    fi
fi
