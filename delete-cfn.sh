#!/bin/bash

# CloudFormation deletion script
# Usage: ./delete-cfn.sh [STACK_NAME] [AWS_REGION]

set -e

STACK_NAME="${1:-workspace-tag-sync-stack}"
AWS_REGION="${2:-us-east-1}"

echo "========================================="
echo "CloudFormation Stack Deletion"
echo "========================================="
echo "Stack Name: $STACK_NAME"
echo "Region: $AWS_REGION"
echo ""

read -p "Are you sure you want to delete this stack? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deletion cancelled."
    exit 0
fi

echo "Deleting CloudFormation stack..."
aws cloudformation delete-stack \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"

echo ""
echo "Stack deleted successfully!"
