#!/bin/bash
set -e

STACK_NAME="my-poc-stack"
S3_BUCKET="mo-poc-s3"   # CodeBuild bucket for packaging
REGION="us-east-1"
CHANGE_SET_NAME="changeset-$(date +%s)"

# Package the template and upload nested stacks automatically
echo "📦 Packaging main template..."
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file packaged.yaml \
  --region $REGION

# Check if stack exists
STACK_EXIST=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].StackName" --output text 2>/dev/null || echo "None")

if [ "$STACK_EXIST" == "None" ]; then
  echo "🆕 Stack does not exist. Creating stack..."
  aws cloudformation deploy \
    --template-file packaged.yaml \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region $REGION
else
  echo "✏️ Stack exists. Creating change set..."
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

  echo "✅ Change set created successfully. Review it in the AWS CloudFormation console."
fi
