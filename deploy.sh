#!/bin/bash
set -e

STACK_NAME="my-poc-stack"
TEMPLATE_FILE="main.yaml"
PACKAGED_FILE="packaged.yaml"
S3_BUCKET="mo-poc-s3"
REGION="us-east-1"

echo "Uploading nested templates and packaging..."
aws cloudformation package \
  --template-file $TEMPLATE_FILE \
  --s3-bucket $S3_BUCKET \
  --output-template-file $PACKAGED_FILE \
  --region $REGION

# Determine if stack exists
if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
  echo "Stack exists. Using UPDATE change set..."
  CHANGESET_TYPE=UPDATE
else
  echo "Stack does not exist. Using CREATE change set..."
  CHANGESET_TYPE=CREATE
fi

CHANGESET_NAME="changeset-$(date +%s)"
echo "Creating change set: $CHANGESET_NAME"

aws cloudformation create-change-set \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME \
  --template-body file://$PACKAGED_FILE \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --change-set-type $CHANGESET_TYPE

echo "Waiting for change set creation to complete..."
aws cloudformation wait change-set-create-complete \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME

echo "Executing change set..."
aws cloudformation execute-change-set \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME

echo "Deployment complete!"
