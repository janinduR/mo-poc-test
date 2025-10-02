#!/bin/bash
set -e

STACK_NAME="my-poc-stack"
TEMPLATE_FILE="main.yaml"
PACKAGED_FILE="packaged.yaml"
S3_BUCKET="mo-poc-s3"
REGION="us-east-1"
BUCKET_PREFIX="poc"

# Package CloudFormation template (uploads nested template to S3)
echo "Packaging template..."
aws cloudformation package \
  --template-file $TEMPLATE_FILE \
  --s3-bucket $S3_BUCKET \
  --output-template-file $PACKAGED_FILE \
  --region $REGION

# Check if stack exists
if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
    echo "Stack exists. Using UPDATE change set..."
    CHANGESET_TYPE="UPDATE"
else
    echo "Stack does not exist. Using CREATE change set..."
    CHANGESET_TYPE="CREATE"
fi

# Generate change set name
CHANGESET_NAME="changeset-$(date +%s)"

# Create change set
echo "Creating change set: $CHANGESET_NAME"
aws cloudformation create-change-set \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME \
  --template-body file://$PACKAGED_FILE \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --change-set-type $CHANGESET_TYPE \
  --parameters ParameterKey=BucketPrefix,ParameterValue=$BUCKET_PREFIX

# Wait for change set to complete
aws cloudformation wait change-set-create-complete \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME || echo "No changes detected or error occurred."

# Execute change set
echo "Executing change set..."
aws cloudformation execute-change-set \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME

echo "Deployment completed successfully!"
