#!/bin/bash
set -e

STACK_NAME="my-poc-stack"
REGION="us-east-1"
CHANGE_SET_NAME="changeset-$(date +%s)"

echo "📦 Packaging main template..."
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file packaged.yaml

# Check if stack exists
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION > /dev/null 2>&1; then
  echo "🛠 Stack exists, creating change set..."
  aws cloudformation create-change-set \
    --stack-name $STACK_NAME \
    --template-body file://packaged.yaml \
    --change-set-name $CHANGE_SET_NAME \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region $REGION

  aws cloudformation wait change-set-create-complete \
    --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME
  echo "✅ Change set created successfully."
else
  echo "🆕 Stack does not exist, creating stack..."
  aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file packaged.yaml \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region $REGION
  echo "✅ Stack created successfully."
fi
