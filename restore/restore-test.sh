#!/bin/bash
# Velero DR Restore Test + RTO Measurement
# Cron: 0 4 * * 1  (every Monday 04:00 UTC)

KUBECONFIG_STANDBY=~/standby-kubeconfig
RESTORE_NAMESPACE='test-app'
LOG_FILE=~/rto-report.log
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo '================================================' | tee -a $LOG_FILE
echo "DR Restore Test Started: $TIMESTAMP" | tee -a $LOG_FILE
echo '================================================' | tee -a $LOG_FILE

# Step 1 — Find latest backup
echo '[1/6] Finding latest backup...' | tee -a $LOG_FILE
LATEST_BACKUP=$(velero backup get --kubeconfig $KUBECONFIG_STANDBY \
  -o json 2>/dev/null | jq -r '.metadata.name')
if [ -z "$LATEST_BACKUP" ] || [ "$LATEST_BACKUP" == 'null' ]; then
  echo 'No backups found!' | tee -a $LOG_FILE; exit 1
fi
echo "Latest backup: $LATEST_BACKUP" | tee -a $LOG_FILE

# Step 2 — Simulate disaster
echo "[2/6] Deleting $RESTORE_NAMESPACE on standby..." | tee -a $LOG_FILE
kubectl --kubeconfig $KUBECONFIG_STANDBY \
  delete namespace $RESTORE_NAMESPACE --ignore-not-found
echo 'Namespace deleted' | tee -a $LOG_FILE

# Step 3 — Record start time
START_TIME=$(date +%s)
echo "[3/6] Restore started at $(date '+%H:%M:%S')" | tee -a $LOG_FILE
echo "RESTORE_START $START_TIME" | tee -a $LOG_FILE

# Step 4 — Trigger restore
RESTORE_NAME="dr-test-$(date +%Y%m%d%H%M%S)"
velero restore create $RESTORE_NAME --from-backup $LATEST_BACKUP \
  --include-namespaces $RESTORE_NAMESPACE --kubeconfig $KUBECONFIG_STANDBY

# Step 5 — Poll until complete
echo '[5/6] Polling restore status...' | tee -a $LOG_FILE
while true; do
  STATUS=$(velero restore get $RESTORE_NAME --kubeconfig $KUBECONFIG_STANDBY \
    -o json 2>/dev/null | jq -r '.status.phase')
  echo "  Status: $STATUS" | tee -a $LOG_FILE
  if [ "$STATUS" == 'Completed' ]; then
    echo 'Restore completed!' | tee -a $LOG_FILE; break
  elif [ "$STATUS" == 'Failed' ] || [ "$STATUS" == 'PartiallyFailed' ]; then
    echo "Restore failed: $STATUS" | tee -a $LOG_FILE; exit 1
  fi
  sleep 10
done

# Step 6 — Calculate RTO
END_TIME=$(date +%s)
RTO=$((END_TIME - START_TIME))
echo "RESTORE_END $END_TIME" | tee -a $LOG_FILE
kubectl --kubeconfig $KUBECONFIG_STANDBY get pods -n $RESTORE_NAMESPACE | tee -a $LOG_FILE
echo '================================================' | tee -a $LOG_FILE
echo "RTO = $RTO seconds ($(( RTO / 60 )) min $(( RTO % 60 )) sec)" | tee -a $LOG_FILE
echo "Restore: $RESTORE_NAME | $(date '+%Y-%m-%d %H:%M:%S')" | tee -a $LOG_FILE
echo '================================================' | tee -a $LOG_FILE
