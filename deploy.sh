#!/bin/bash
set -e

# Variables
STACK_NAME="my-poc-stack"
TEMPLATE_FILE="main.yaml"
PACKAGED_FILE="packaged.yaml"
S3_BUCKET="mo-poc-s3"
REGION="us-east-1"
CHANGESET_NAME="changeset-$(date +%s)"
CHILD_TEMPLATE_S3_URL="https://s3.amazonaws.com/$S3_BUCKET/child-template.yaml"

# Upload child template to S3 (if not already uploaded)
echo "Uploading child template to S3..."
aws s3 cp child-template.yaml s3://$S3_BUCKET/child-template.yaml --region $REGION

# Package parent template (handles nested templates)
echo "Packaging parent template..."
aws cloudformation package \
    --template-file $TEMPLATE_FILE \
    --s3-bucket $S3_BUCKET \
    --output-template-file $PACKAGED_FILE \
    --region $REGION

# Determine change set type
if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
    echo "Stack exists. Using UPDATE change set..."
    CHANGESET_TYPE="UPDATE"
else
    echo "Stack does not exist. Using CREATE change set..."
    CHANGESET_TYPE="CREATE"
fi

# Create change set with ChildTemplateS3Url parameter
echo "Creating change set $CHANGESET_NAME..."
aws cloudformation create-change-set \
    --stack-name $STACK_NAME \
    --change-set-name $CHANGESET_NAME \
    --template-body file://$PACKAGED_FILE \
    --parameters ParameterKey=ChildTemplateS3Url,ParameterValue=$CHILD_TEMPLATE_S3_URL \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --change-set-type $CHANGESET_TYPE \
    --region $REGION

# Wait for change set creation to complete
echo "Waiting for change set creation to complete..."
aws cloudformation wait change-set-create-complete \
    --stack-name $STACK_NAME \
    --change-set-name $CHANGESET_NAME \
    --region $REGION || echo "No changes or error"

echo "Change set created: $CHANGESET_NAME"
echo "You can execute it using:"
echo "aws cloudformation execute-change-set --stack-name $STACK_NAME --change-set-name $CHANGESET_NAME"
