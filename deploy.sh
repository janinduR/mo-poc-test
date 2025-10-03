#!/bin/bash
set -e

STACK_NAME="my-poc-stack"
S3_BUCKET="mo-poc-s3"
REGION="us-east-1"
CHANGE_SET_NAME="changeset-$(date +%s)"

echo "🚀 Uploading child template to S3..."
aws s3 cp child-template.yaml s3://$S3_BUCKET/child-template.yaml

echo "📦 Packaging main template..."
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file packaged.yaml

echo "🛠️ Creating change set: $CHANGE_SET_NAME..."
aws cloudformation create-change-set \
  --stack-name $STACK_NAME \
  --template-body file://packaged.yaml \
  --change-set-name $CHANGE_SET_NAME \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --parameters ParameterKey=ChildTemplateS3Url,ParameterValue="https://$S3_BUCKET.s3.amazonaws.com/child-template.yaml" \
  --region $REGION

echo "⏳ Waiting for change set creation to complete..."
aws cloudformation wait change-set-create-complete \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGE_SET_NAME

echo "✅ Change set created successfully. Review it in the AWS CloudFormation console:"
echo "   - Stack Name: $STACK_NAME"
echo "   - Change Set Name: $CHANGE_SET_NAME"
