#!/bin/bash
set -e

CHANGESET_NAME="changeset-$CODEBUILD_RESOLVED_SOURCE_VERSION"

if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
  CHANGESET_TYPE=UPDATE
else
  CHANGESET_TYPE=CREATE
fi

echo "Change set type: $CHANGESET_TYPE"

aws cloudformation create-change-set \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME \
  --template-body file://$PACKAGED_FILE \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --change-set-type $CHANGESET_TYPE

aws cloudformation wait change-set-create-complete \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGESET_NAME || echo "No changes or error"

echo "Change set completed: $CHANGESET_NAME"
