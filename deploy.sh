#!/bin/bash
set -e

# Variables
TEMPLATE_FILE="main.yaml"
PACKAGED_FILE="packaged.yaml"
S3_BUCKET="mo-poc-s3"
STACK_NAME="my-poc-stack"
REGION="us-east-1"
CHANGESET_NAME="changeset-$(date +%s)"

echo "Packaging nested templates..."
aws cloudformation package \
    --template-file $TEMPLATE_FILE \
    --s3-bucket $S3_BUCKET \
    --output-template-file $PACKAGED_FILE

echo "Creating change set: $CHANGESET_NAME..."

# Determine if stack exists
if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
    echo "Stack exists. Using UPDATE change set..."
    CHANGESET_TYPE=UPDATE
else
    echo "Stack does not exist. Using CREATE change set..."
    CHANGESET_TYPE=CREATE
fi

# Create change set without executing
aws cloudformation create-change-set \
    --stack-name $STACK_NAME \
    --change-set-name $CHANGESET_NAME \
    --template-body file://$PACKAGED_FILE \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --change-set-type $CHANGESET_TYPE

echo "Change set created: $CHANGESET_NAME"
echo "Review it in the AWS Console before executing."
