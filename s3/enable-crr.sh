#!/bin/bash
set -e
ACCOUNT_ID='992234856455'
PRIMARY_BUCKET="velero-backup-primary-${ACCOUNT_ID}"
REPLICA_BUCKET="velero-backup-replica-${ACCOUNT_ID}"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/S3ReplicationRole"

echo 'Enabling Cross-Region Replication...'
aws s3api put-bucket-replication \
  --bucket ${PRIMARY_BUCKET} \
  --replication-configuration '{
    "Role": "'${ROLE_ARN}'",
    "Rules": [{
      "ID": "velero-crr-rule",
      "Priority": 1,
      "Status": "Enabled",
      "Filter": {"Prefix": ""},
      "Destination": {
        "Bucket": "arn:aws:s3:::'${REPLICA_BUCKET}'",
        "StorageClass": "STANDARD"
      },
      "DeleteMarkerReplication": {"Status": "Enabled"}
    }]
  }'

echo 'Verifying CRR...'
aws s3api get-bucket-replication --bucket ${PRIMARY_BUCKET}
echo 'Done! All objects auto-replicate to us-west-2.'
