#!/bin/bash
set -e

STACK_NAME="my-poc-stack"
S3_BUCKET="your-cf-bucket"  # CodeBuild artifact bucket
REGION="us-east-1"
CHANGE_SET_NAME="changeset-$(date +%s)"

echo "📦 Packaging CloudFormation templates..."
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file packaged.yaml \
  --region $REGION

# Check if stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].StackName" --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$STACK_EXISTS" == "NOT_FOUND" ]; then
  echo "🆕 Creating new stack $STACK_NAME..."
  aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://packaged.yaml \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region $REGION
else
  echo "⚡ Stack exists. Creating change set $CHANGE_SET_NAME..."
  aws cloudformation create-change-set \
    --stack-name $STACK_NAME \
    --template-body file://packaged.yaml \
    --change-set-name $CHANGE_SET_NAME \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region $REGION

  echo "⏳ Waiting for change set creation to complete..."
  aws cloudformation wait change-set-create-complete \
    --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME

  echo "✅ Change set created successfully."
fi
