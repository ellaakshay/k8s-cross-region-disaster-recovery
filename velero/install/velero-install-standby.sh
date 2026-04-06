#!/bin/bash
# Velero Install — Standby Cluster (us-west-2)
set -e

BUCKET='velero-backup-replica-992234856455'
REGION='us-west-2'
KUBECONFIG_FILE=~/standby-kubeconfig
CREDENTIALS_FILE=~/credentials-velero
PLUGIN_VERSION='v1.9.0'

echo '[1/3] Installing Velero on standby cluster...'
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:${PLUGIN_VERSION} \
  --bucket ${BUCKET} \
  --backup-location-config region=${REGION} \
  --snapshot-location-config region=${REGION} \
  --secret-file ${CREDENTIALS_FILE} \
  --use-volume-snapshots=true \
  --kubeconfig ${KUBECONFIG_FILE}

echo '[2/3] Setting BackupStorageLocation to ReadOnly...'
kubectl --kubeconfig ${KUBECONFIG_FILE} \
  patch backupstoragelocation default -n velero \
  --type merge -p '{"spec":{"accessMode":"ReadOnly"}}'

echo '[3/3] Verifying...'
kubectl --kubeconfig ${KUBECONFIG_FILE} get pods -n velero
velero backup get --kubeconfig ${KUBECONFIG_FILE}
echo 'Done! Velero running on standby in ReadOnly mode.'
