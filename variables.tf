variable "aws_account_id" {
  type        = string
  description = "REQUIRED: AWS Account ID to deploy"
}

variable "aws_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "OPTIONAL: AWS Region to deploy"
}

variable "lambda_function_name" {
  type        = string
  default     = "terraform-rds-continuous-shutdown"
  description = "REQUIRED: Lambda Function name"
}

variable "db_matcher_name" {
  type        = string
  default     = "sample"
  description = "OPTIONAL: a comma separated substring of to stop DB Cluster name, ex: sample,test"
}

variable "cloudwatch_start_schedule" {
  type        = string
  default     = "cron(0 22 ? * SUN *)"
  description = "OPTIONAL: a cron expression that periodically start RDS"
}

variable "cloudwatch_stop_schedule" {
  type        = string
  default     = "cron(30 22 ? * SUN *)"
  description = "OPTIONAL: a cron expression that periodically stop RDS"
}
