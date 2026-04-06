#!/bin/bash
# ---------------------------------------------------------------------------------------------------------
# RTO Metric Summary Report
# ---------------------------------------------------------------------------------------------------------

LOG_FILE="./restore/rto-report.log"

if [[ ! -f $LOG_FILE ]]; then
    echo "Error: RTO Log file not found at $LOG_FILE"
    exit 1
fi

echo "--------------------------------------------------------"
echo "Disaster Recovery Performance Summary (RTO)"
echo "--------------------------------------------------------"
echo "Total Drills Run: $(wc -l < $LOG_FILE)"
echo ""

# Extract RTO seconds and calculate average
AVG_RTO=$(awk -F'RTO=' '{print $2}' $LOG_FILE | awk '{print $1}' | awk '{ total += $1; count++ } END { if (count > 0) print total / count; else print 0 }')
MIN_RTO=$(awk -F'RTO=' '{print $2}' $LOG_FILE | awk '{print $1}' | sort -n | head -1)
MAX_RTO=$(awk -F'RTO=' '{print $2}' $LOG_FILE | awk '{print $1}' | sort -nr | head -1)

echo "Average RTO: $AVG_RTO seconds"
echo "Minimum RTO: $MIN_RTO seconds"
echo "Maximum RTO: $MAX_RTO seconds"

echo "--------------------------------------------------------"
echo "Recent Drills (Last 5):"
tail -n 5 $LOG_FILE
echo "--------------------------------------------------------"
