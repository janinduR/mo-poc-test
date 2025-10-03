#!/bin/bash
set -e

# Variables
STACK_NAME="my-poc-stack"
PACKAGED_FILE="packaged.yaml"
REGION="us-east-1"
CHANGESET_NAME="changeset-$(date +%s)"

echo "Stack name: $STACK_NAME"
echo "Change set name: $CHANGESET_NAME"

# Determine if stack exists
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
  echo "Stack exists. Using UPDATE change set..."
  CHANGESET_TYPE="UPDATE"
else
  echo "Stack does not exist. Using CREATE change set..."
  CHANGESET_TYPE="CREATE"
fi

# Create change set
echo "Creating change set..."
aws cloudformation create-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGESET_NAME" \
  --template-body file://"$PACKAGED_FILE" \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --change-set-type "$CHANGESET_TYPE"

echo "Change set created successfully: $CHANGESET_NAME"
echo "Review it in the CloudFormation console to see property-level changes, including child stack changes."
