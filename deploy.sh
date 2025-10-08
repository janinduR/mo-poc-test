#!/bin/bash
set -e

STACK_NAME="mo-wso2-dev"
S3_BUCKET="mo-poc-s3"
REGION="us-east-1"
CHANGE_SET_NAME="changeset-$(date +%s)"

echo "📦 Packaging templates..."
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file packaged.yaml

echo "🛠️ Creating change set..."
aws cloudformation create-change-set \
  --stack-name $STACK_NAME \
  --template-body file://packaged.yaml \
  --change-set-name $CHANGE_SET_NAME \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --region $REGION

echo "⏳ Waiting for change set..."
aws cloudformation wait change-set-create-complete \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGE_SET_NAME

echo "✅ Done. Change set created: $CHANGE_SET_NAME"
