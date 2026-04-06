#!/bin/bash
# Velero Install — Primary Cluster (us-east-1)
set -e

BUCKET='velero-backup-primary-992234856455'
REGION='us-east-1'
KUBECONFIG_FILE=~/primary-kubeconfig
CREDENTIALS_FILE=~/credentials-velero
PLUGIN_VERSION='v1.9.0'

echo '[1/3] Verifying Velero CLI...'
velero version --client-only

echo '[2/3] Installing Velero on primary cluster...'
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:${PLUGIN_VERSION} \
  --bucket ${BUCKET} \
  --backup-location-config region=${REGION} \
  --snapshot-location-config region=${REGION} \
  --secret-file ${CREDENTIALS_FILE} \
  --use-volume-snapshots=true \
  --kubeconfig ${KUBECONFIG_FILE}

echo '[3/3] Verifying...'
kubectl --kubeconfig ${KUBECONFIG_FILE} get pods -n velero
kubectl --kubeconfig ${KUBECONFIG_FILE} get backupstoragelocation -n velero
echo 'Done! Velero running on primary.'
