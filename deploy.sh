#!/bin/bash
set -e

# ==== CONFIGURATION ====
STACK_NAME="mo-wso2-dev"
S3_BUCKET="mo-poc-s3"
REGION="us-east-1"
CHANGE_SET_NAME="changeset-$(date +%s)"

echo "📦 Packaging CloudFormation templates (including nested stacks)..."
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file packaged.yaml

echo "✅ Packaging complete. All nested templates uploaded to S3."

# ==== CHECK IF STACK EXISTS ====
echo "🔍 Checking if CloudFormation stack '$STACK_NAME' exists..."
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "✅ Stack '$STACK_NAME' exists. Creating a change set for update..."

  aws cloudformation create-change-set \
    --stack-name "$STACK_NAME" \
    --template-body file://packaged.yaml \
    --change-set-name "$CHANGE_SET_NAME" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region "$REGION"

  echo "⏳ Waiting for change set to be created..."
  aws cloudformation wait change-set-create-complete \
    --stack-name "$STACK_NAME" \
    --change-set-name "$CHANGE_SET_NAME" \
    --region "$REGION"

  echo "✅ Change set created successfully:"
  echo "   Stack Name: $STACK_NAME"
  echo "   Change Set: $CHANGE_SET_NAME"

else
  echo "🆕 Stack '$STACK_NAME' does not exist. Creating a new stack..."

  aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body file://packaged.yaml \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region "$REGION"

  echo "⏳ Waiting for stack creation to complete..."
  aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

  echo "✅ Stack '$STACK_NAME' created successfully!"
fi

