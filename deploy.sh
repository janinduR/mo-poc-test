#!/bin/bash
set -e

echo "📦 Packaging CloudFormation templates..."
aws cloudformation package \
  --template-file main.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file packaged.yaml \
  --region $REGION

echo "🚀 Creating or updating CloudFormation stack: $STACK_NAME"
aws cloudformation deploy \
  --template-file packaged.yaml \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --region $REGION

echo "✅ Stack deployment complete!"

# Optional: describe stack outputs
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $REGION \
  --query "Stacks[0].Outputs"
