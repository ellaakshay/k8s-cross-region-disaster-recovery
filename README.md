# 🛡️ Velero Disaster Recovery: Cross-Region K8s Backup & Restore

[![Velero](https://img.shields.io/badge/Provider-Velero-blue?logo=velero&logoColor=white)](https://velero.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Platform-Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)

This Proof of Concept (**POC**) demonstrates a production-grade **Disaster Recovery (DR)** pipeline for Kubernetes workloads using Velero. The solution automates full namespace backups, including Persistent Volume Claims (PVCs) as EBS snapshots, replicated across AWS regions to ensure business continuity.

---

## 📌 Project Overview
The primary goal is to close the gap between "having a backup" and "having a proven recovery path".

- **Infrastructure**: Self-managed Kubeadm clusters on AWS EC2.
- **Storage**: Amazon S3 with **Cross-Region Replication (CRR)** enabled between `us-east-1` (Primary) and `us-west-2` (Standby).
- **Automation**: Weekly restore drills on a standby cluster to measure and report the **Recovery Time Objective (RTO)**.

---

## 📂 Repository Structure
The project is organized into modular components for infrastructure, configuration, and automation:

```plaintext
velero-dr/
├── velero/
│   ├── install/          # Scripts for Primary & Standby Velero setup
│   ├── schedules/        # Daily backup CRD manifests
│   └── configs/          # AWS credentials (gitignored)
├── s3/                   # Bucket creation and CRR configuration
├── iam/                  # Least-privilege IAM policy for Velero
├── restore/              # RTO measurement and restore drill scripts
└── manifests/            # Sample stateful app for testing
```

---

## 🚀 Implementation Steps

### Step 1: AWS Foundation
1.  **IAM**: Create the `VeleroPolicy` using `iam/velero-iam-policy.json` and attach it to a dedicated `velero` user.
2.  **S3**: Create the primary bucket in `us-east-1` and the replica bucket in `us-west-2`.
3.  **Versioning**: Enable versioning on both buckets (required for CRR).
4.  **Replication**: Apply the CRR configuration to the primary bucket to automate object syncing.

### Step 2: Install Velero (Primary Cluster)
Install Velero on your production cluster pointing to the primary bucket:

```bash
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.9.0 \
  --bucket velero-backup-primary \
  --backup-location-config region=us-east-1 \
  --snapshot-location-config region=us-east-1 \
  --secret-file ./velero/configs/credentials-velero \
  --use-volume-snapshots=true \
  --features=EnableCSI
```

### Step 3: Automated Backups
Apply the schedule manifest to perform a full-cluster backup daily at **02:00 UTC** with a **7-day retention period**.

### Step 4: Standby Cluster Configuration
Switch to your standby cluster context and install Velero pointing to the replica bucket in `us-west-2`. This allows the standby cluster to "see" the replicated backups from the primary region.

---

## 📊 Recovery Testing & RTO
The core metric for this POC is the **Recovery Time Objective (RTO)**—the time taken from starting a restore until all pods are `Running`.

### Restore Drill Logic (`restore-test.sh`)
1.  Deletes the existing test namespace to ensure a clean environment.
2.  Identifies the latest backup in the replica bucket.
3.  Triggers the Velero restore and polls for completion.
4.  Calculates RTO in seconds and logs it to `rto-report.log`.

### RTO Benchmarks
| Metric | Target | POC Typical Result |
| :--- | :--- | :--- |
| **Full Namespace (No PVC)** | < 5 min | 1–3 min |
| **Full Restore (EBS < 20GB)** | < 15 min | 7–12 min |
| **S3 CRR Lag** | < 15 min | < 5 min |

---

## 🛠️ Troubleshooting

> [!TIP]
> Always check the Velero logs first: `velero backup logs <backup-name>`

- **BackupStorageLocation Unavailable**: Verify IAM credentials and S3 network connectivity.
- **EBS Snapshot Fails**: Ensure `ec2:CreateSnapshot` is present in the IAM policy.
- **PVC Not Restored**: Ensure the `StorageClass` name on the standby cluster matches the primary cluster exactly.
