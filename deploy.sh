#!/bin/bash
set -e

# Upload child template to S3
echo "Uploading child template to S3..."
CHILD_TEMPLATE_S3_URL=$(aws s3 cp "$CHILD_TEMPLATE_FILE" "s3://$S3_BUCKET/" --output text)
CHILD_TEMPLATE_S3_URL="https://$S3_BUCKET.s3.amazonaws.com/$CHILD_TEMPLATE_FILE"
echo "Child template URL: $CHILD_TEMPLATE_S3_URL"

# Package main template
echo "Packaging main template..."
aws cloudformation package \
    --template-file "$TEMPLATE_FILE" \
    --s3-bucket "$S3_BUCKET" \
    --output-template-file "$PACKAGED_FILE" \
    --use-json

# Create change set name
CHANGESET_NAME="changeset-$(date +%s)"
echo "Change set name: $CHANGESET_NAME"

# Determine whether to CREATE or UPDATE
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    CHANGESET_TYPE="UPDATE"
    echo "Stack exists. Using UPDATE change set..."
else
    CHANGESET_TYPE="CREATE"
    echo "Stack does not exist. Using CREATE change set..."
fi

# Create change set
echo "Creating change set..."
aws cloudformation create-change-set \
    --stack-name "$STACK_NAME" \
    --change-set-name "$CHANGESET_NAME" \
    --template-body "file://$PACKAGED_FILE" \
    --parameters ParameterKey=ChildTemplateS3Url,ParameterValue="$CHILD_TEMPLATE_S3_URL" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --change-set-type "$CHANGESET_TYPE"

echo "Change set created: $CHANGESET_NAME"
echo "Please validate in AWS console before execution."
