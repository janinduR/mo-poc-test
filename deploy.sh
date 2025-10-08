#!/bin/bash
set -e

STACK_NAME="mo-wso2-dev"
S3_BUCKET="mo-poc-s3"
REGION="us-east-1"

echo "📦 Packaging CloudFormation templates..."
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file packaged.yaml

echo "✅ Packaging complete. All nested templates uploaded to S3."

# Check if the stack exists
echo "🔍 Checking if CloudFormation stack '$STACK_NAME' exists..."
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION >/dev/null 2>&1; then
    echo "🛠️ Stack exists. Creating a change set..."
    CHANGE_SET_NAME="changeset-$(date +%s)"
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
    echo "🆕 Stack '$STACK_NAME' does not exist. Creating a new stack..."
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://packaged.yaml \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
        --region $REGION

    echo "⏳ Waiting for stack creation to complete..."
    # Wrap in try-catch to continue even if creation fails
    set +e
    aws cloudformation wait stack-create-complete \
        --stack-name $STACK_NAME
    STATUS=$?
    set -e

    if [ $STATUS -ne 0 ]; then
        echo "⚠️ Stack creation failed. Fetching failure reasons..."
        aws cloudformation describe-stack-events \
            --stack-name $STACK_NAME \
            --region $REGION \
            --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].[Timestamp, ResourceType, LogicalResourceId, ResourceStatusReason]" \
            --output table
        exit 1
    fi

    echo "✅ Stack created successfully."
fi
