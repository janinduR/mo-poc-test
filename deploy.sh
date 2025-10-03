#!/bin/bash
set -e

STACK_NAME="my-poc-stack"
S3_BUCKET="mo-poc-s3"
PACKAGED_FILE="packaged.yaml"
TEMPLATE_FILE="main.yaml"
CHILD_TEMPLATE_FILE="child-template.yaml"

echo "Uploading child template..."
aws s3 cp $CHILD_TEMPLATE_FILE s3://$S3_BUCKET/

CHILD_TEMPLATE_URL="https://s3.amazonaws.com/$S3_BUCKET/$CHILD_TEMPLATE_FILE"
echo "Child template URL: $CHILD_TEMPLATE_URL"

echo "Packaging parent template..."
aws cloudformation package \
  --template-file $TEMPLATE_FILE \
  --s3-bucket $S3_BUCKET \
  --output-template-file $PACKAGED_FILE

CHANGESET_NAME="changeset-$(date +%s)"
echo "Creating change set: $CHANGESET_NAME..."

if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
  echo "Stack exists. Using UPDATE change set..."
  CHANGESET_TYPE=UPDATE
else
  echo "Stack does not exist. Using CREATE change set..."
  CHANGESET_TYPE=CREATE
fi

aws cloudformation create-change-set \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME \
  --template-body file://$PACKAGED_FILE \
  --parameters ParameterKey=ChildTemplateS3Url,ParameterValue=$CHILD_TEMPLATE_URL \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --change-set-type $CHANGESET_TYPE

echo "Waiting for change set to be created..."
aws cloudformation wait change-set-create-complete --stack-name $STACK_NAME --change-set-name $CHANGESET_NAME

echo "Executing change set..."
aws cloudformation execute-change-set --stack-name $STACK_NAME --change-set-name $CHANGESET_NAME

echo "Deployment complete ✅"
