# WorkSpace Tag Sync Lambda Function

This Lambda function automatically pulls tags from AWS WorkSpaces and applies them to associated Fleet Manager (SSM) instances. Deployed via CloudFormation with hourly execution.

## Features

- Retrieves all WorkSpaces in your AWS account
- Extracts tags from each WorkSpace
- Identifies associated Fleet Manager instances
- Applies WorkSpace tags to Fleet Manager instances
- Runs automatically every hour via EventBridge
- Comprehensive logging and error handling
- CloudWatch alarm for error monitoring

## Prerequisites

- AWS CLI installed and configured
- Appropriate AWS credentials with permissions to:
  - Create/manage CloudFormation stacks
  - Create/manage Lambda functions
  - Create/manage IAM roles and policies
  - Access WorkSpaces and SSM services

## Project Structure

```
.
├── template.yaml          # CloudFormation template
├── deploy-cfn.sh          # Deployment script
├── delete-cfn.sh          # Deletion script
└── README.md              # This file
```

## Deployment

Deploy using CloudFormation:

```bash
chmod +x deploy-cfn.sh delete-cfn.sh
./deploy-cfn.sh workspace-tag-sync-stack us-east-1
```

This will:
1. Create IAM roles with necessary permissions
2. Deploy Lambda function with inline code
3. Set up hourly EventBridge schedule (modern scheduler)
4. Create CloudWatch log group and alarm
5. Configure all permissions automatically

Custom deployment:
```bash
./deploy-cfn.sh [STACK_NAME] [AWS_REGION]
```

Example:
```bash
./deploy-cfn.sh my-workspace-sync us-west-2
```

## Testing

After deployment, manually invoke the function:

```bash
aws lambda invoke \
    --function-name workspace-tag-sync \
    --region us-east-1 \
    response.json

cat response.json
```

## Monitoring

View Lambda logs:

```bash
aws logs tail /aws/lambda/workspace-tag-sync --follow --region us-east-1
```

## Configuration

### IAM Permissions

The Lambda function requires:
- `workspaces:DescribeWorkspaces` - List all WorkSpaces
- `workspaces:DescribeTags` - Read WorkSpace tags
- `ssm:DescribeInstanceInformation` - Find Fleet Manager instances
- `ssm:AddTagsToResource` - Apply tags to instances
- CloudWatch Logs permissions for logging

### Timeout and Memory

Default settings (configurable in template.yaml):
- Timeout: 300 seconds (5 minutes)
- Memory: 256 MB
- Schedule: Every hour

## How It Works

1. **Retrieve WorkSpaces**: Fetches all WorkSpaces in the account
2. **Get Tags**: Extracts tags from each WorkSpace
3. **Find Instances**: Locates associated Fleet Manager instances by:
   - Matching WorkspaceId tag
   - Matching ComputerName
4. **Apply Tags**: Copies WorkSpace tags to Fleet Manager instances
5. **Report Results**: Returns detailed execution summary

## Response Format

```json
{
  "statusCode": 200,
  "body": {
    "total_workspaces": 10,
    "successful": 8,
    "failed": 1,
    "no_instance_found": 1,
    "details": [
      {
        "workspace_id": "ws-abc123",
        "instance_id": "mi-xyz789",
        "tags_applied": 5,
        "status": "success"
      }
    ]
  }
}
```

## Scheduling

The CloudFormation template automatically creates an EventBridge Schedule to run the function every hour. You can customize the schedule by modifying the `ScheduleExpression` parameter in `template.yaml`.

Supported schedule expressions:
- `rate(1 hour)` - Every hour (default)
- `rate(30 minutes)` - Every 30 minutes
- `rate(1 day)` - Daily
- `cron(0 * * * ? *)` - Every hour (cron format)
- `cron(0 9 * * ? *)` - Daily at 9 AM UTC

To change the schedule, edit `template.yaml` and redeploy:
```bash
./deploy-cfn.sh workspace-tag-sync-stack us-east-1
```

The schedule includes:
- Automatic retry on failure (up to 2 retries)
- Dedicated IAM role for scheduler execution

## Troubleshooting

### No instances found
- Ensure WorkSpaces are registered with Fleet Manager (SSM)
- Verify instances have the WorkspaceId tag
- Check that SSM agent is running on WorkSpace instances

### Permission errors
- Verify IAM role has all required permissions
- Check resource-based policies on WorkSpaces and SSM

### Timeout errors
- Increase Lambda timeout in deploy.sh
- Consider processing WorkSpaces in batches

## Cleanup

Remove all deployed resources:

```bash
./delete-cfn.sh workspace-tag-sync-stack us-east-1
```

This will delete the entire CloudFormation stack including:
- Lambda function
- IAM roles and policies
- EventBridge schedule
- CloudWatch log group and alarm

## Cost Considerations

- Lambda: Pay per invocation and execution time
- CloudWatch Logs: Storage and data transfer
- API calls: WorkSpaces and SSM API requests

Estimated cost for 100 WorkSpaces with daily sync: < $1/month

## Security Best Practices

- Use least-privilege IAM policies
- Enable CloudTrail logging
- Encrypt sensitive tags
- Review and audit tag propagation regularly
- Use VPC endpoints for private API access

## Customization

To customize the Lambda function code, edit the `Code.ZipFile` section in `template.yaml`:

### Filter WorkSpaces
Modify `get_all_workspaces()` to filter by directory, bundle, or tags.

### Custom Tag Mapping
Update `apply_tags_to_instance()` to transform or filter tags before applying.

### Batch Processing
Implement pagination for large WorkSpace fleets.

After making changes, redeploy the stack to apply updates.

## Support

For issues or questions:
1. Check CloudWatch Logs for detailed error messages
2. Verify IAM permissions
3. Test with a small subset of WorkSpaces first

## License

This code is provided as-is for use in your AWS environment.
