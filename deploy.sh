#!/bin/bash
set -e

STACK_NAME="my-poc-stack"
TEMPLATE_FILE="main.yaml"
CHILD_TEMPLATE_FILE="child-template.yaml"
PACKAGED_FILE="packaged.yaml"
S3_BUCKET="mo-poc-s3"

echo "Uploading child template to S3..."
aws s3 cp $CHILD_TEMPLATE_FILE s3://$S3_BUCKET/$CHILD_TEMPLATE_FILE
CHILD_TEMPLATE_S3_URL="https://s3.amazonaws.com/$S3_BUCKET/$CHILD_TEMPLATE_FILE"

echo "Packaging parent template..."
aws cloudformation package \
    --template-file $TEMPLATE_FILE \
    --s3-bucket $S3_BUCKET \
    --output-template-file $PACKAGED_FILE

CHANGESET_NAME="changeset-$(date +%s)"

# Determine if stack exists
if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
    echo "Stack exists. Using UPDATE change set..."
    CHANGESET_TYPE=UPDATE
else
    echo "Stack does not exist. Using CREATE change set..."
    CHANGESET_TYPE=CREATE
fi

# Create change set with dynamic ChildTemplateS3Url parameter
aws cloudformation create-change-set \
    --stack-name $STACK_NAME \
    --change-set-name $CHANGESET_NAME \
    --template-body file://$PACKAGED_FILE \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --change-set-type $CHANGESET_TYPE \
    --parameters ParameterKey=ChildTemplateS3Url,ParameterValue=$CHILD_TEMPLATE_S3_URL

echo "Change set created: $CHANGESET_NAME"
echo "You can review the change set in the CloudFormation console before executing."
