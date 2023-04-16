# AWS Lambda RDS Continuous Stopping Module

This Terraform module deploys a Lambda function to continuously stop RDS.

RDS instances automatically start after being stopped for one week.
Despite being stopped for cost optimization, there is a risk of unintended billing if left unattended, as instances start automatically.

This Lambda function starts the specified RDS instances at a cron schedule, and then immediately stops them again. By running this process every week, the Lambda function ensures that RDS instances remain stopped, supporting cost optimization.

It is recommended to set the cron schedule according to the maintenance window of the RDS instances.

## Input Variables

| Name                       | Type   | Default                           | Description                                                                           | Required |
|----------------------------|--------|-----------------------------------|---------------------------------------------------------------------------------------|----------|
| aws_account_id             | string |                                   | AWS Account ID for deployment                                                         | Yes      |
| aws_region                 | string | ap-northeast-1                    | AWS Region for deployment                                                             | No       |
| lambda_function_name       | string | terraform-rds-continuous-stopping | Name of the Lambda Function                                                           | Yes      |
| db_matcher_name            | string | sample                            | A comma-separated list of substrings for matching DB Cluster names, e.g., sample,test | No       |
| cloudwatch_start_schedule  | string | cron(0 22 ? * SUN *)              | A cron expression to periodically start DB Clusters                                   | No       |
| cloudwatch_stop_schedule   | string | cron(30 22 ? * SUN *)             | A cron expression to periodically stop DB Clusters                                    | No       |
