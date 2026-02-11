#!/bin/bash

# CloudFormation deployment script for WorkSpace Tag Sync Lambda
# Usage: ./deploy-cfn.sh [STACK_NAME] [AWS_REGION]

set -e

STACK_NAME="${1:-workspace-tag-sync-stack}"
AWS_REGION="${2:-us-east-1}"

echo "========================================="
echo "CloudFormation Deployment"
echo "========================================="
echo "Stack Name: $STACK_NAME"
echo "Region: $AWS_REGION"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Validate the template
echo "Validating CloudFormation template..."
aws cloudformation validate-template \
    --template-body file://template.yaml \
    --region "$AWS_REGION" > /dev/null

echo "Template is valid!"
echo ""

# Check if stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].StackName' \
    --output text 2>/dev/null || echo "")

if [ -n "$STACK_EXISTS" ]; then
    echo "Stack exists. Updating..."
    OPERATION="update-stack"
    WAITER="stack-update-complete"
else
    echo "Stack does not exist. Creating..."
    OPERATION="create-stack"
    WAITER="stack-create-complete"
fi

# Deploy the stack
echo "Deploying CloudFormation stack..."
aws cloudformation "$OPERATION" \
    --stack-name "$STACK_NAME" \
    --template-body file://template.yaml \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region "$AWS_REGION" \
    --parameters \
        ParameterKey=FunctionName,ParameterValue=workspace-tag-sync \
        ParameterKey=ScheduleExpression,ParameterValue="rate(1 hour)" \
        ParameterKey=LambdaTimeout,ParameterValue=300 \
        ParameterKey=LambdaMemory,ParameterValue=256 \
    --tags \
        Key=Project,Value=WorkspaceTagSync \
        Key=ManagedBy,Value=CloudFormation

echo ""
echo "Waiting for stack operation to complete..."
aws cloudformation wait "$WAITER" \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="

# Get stack outputs
echo ""
echo "Stack Outputs:"
aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

echo ""
echo "To view logs:"
echo "  aws logs tail /aws/lambda/workspace-tag-sync --follow --region $AWS_REGION"
echo ""
echo "To manually invoke the function:"
echo "  aws lambda invoke --function-name workspace-tag-sync --region $AWS_REGION response.json"
echo ""
echo "To delete the stack:"
echo "  ./delete-cfn.sh $STACK_NAME $AWS_REGION"
