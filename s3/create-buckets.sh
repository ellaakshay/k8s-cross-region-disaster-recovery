#!/bin/bash
set -e
ACCOUNT_ID='992234856455'
PRIMARY_BUCKET="velero-backup-primary-${ACCOUNT_ID}"
REPLICA_BUCKET="velero-backup-replica-${ACCOUNT_ID}"

echo '[1/4] Creating primary bucket (us-east-1)...'
aws s3api create-bucket --bucket ${PRIMARY_BUCKET} --region us-east-1

echo '[2/4] Enabling versioning on primary...'
aws s3api put-bucket-versioning --bucket ${PRIMARY_BUCKET} \
  --versioning-configuration Status=Enabled

echo '[3/4] Creating replica bucket (us-west-2)...'
aws s3api create-bucket --bucket ${REPLICA_BUCKET} --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

echo '[4/4] Enabling versioning on replica...'
aws s3api put-bucket-versioning --bucket ${REPLICA_BUCKET} \
  --versioning-configuration Status=Enabled

echo 'Verifying...'
aws s3api get-bucket-versioning --bucket ${PRIMARY_BUCKET}
aws s3api get-bucket-versioning --bucket ${REPLICA_BUCKET}
echo 'Done! Both buckets ready with versioning.'
