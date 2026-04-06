#!/bin/bash
# ---------------------------------------------------------------------------------------
# AWS IAM Setup for Velero DR Pipeline
# ---------------------------------------------------------------------------------------

USER_NAME="velero-dr-user"
POLICY_NAME="VeleroDRPolicy"
POLICY_FILE="iam/velero-iam-policy.json"

echo "--------------------------------------------------------"
echo "Starting IAM Foundation Setup"
echo "--------------------------------------------------------"

echo "[1/4] Creating IAM user: $USER_NAME..."
aws iam create-user --user-name $USER_NAME

echo "[2/4] Creating IAM policy: $POLICY_NAME from $POLICY_FILE..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"

aws iam create-policy --policy-name $POLICY_NAME --policy-document file://$POLICY_FILE

echo "[3/4] Attaching policy to user..."
aws iam attach-user-policy --user-name $USER_NAME --policy-arn $POLICY_ARN

echo "[4/4] Generating access keys for Velero installation..."
aws iam create-access-key --user-name $USER_NAME > ./velero/configs/credentials-velero

echo "--------------------------------------------------------"
echo "IAM Setup Complete"
echo "Credentials saved to ./velero/configs/credentials-velero"
echo "--------------------------------------------------------"
