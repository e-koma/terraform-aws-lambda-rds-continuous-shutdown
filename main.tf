resource "aws_iam_role" "lambda_role" {
  name               = "terraform-rds-keep-stopping-lambda-role"
  description        = "role for lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  inline_policy {
    name = "terraform-rds-keep-stopping-lambda-inline-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*",
          ]
        },
        {
          Action = [
            "rds:DescribeDBClusters",
            "rds:StartDBCluster",
            "rds:StopDBCluster"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:rds:${var.aws_region}:${var.aws_account_id}:cluster:*"
        },
      ]
    })
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "archive_file" "lambda_archive_file" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/rds_keep_stopping"
  output_path = "${path.module}/lambda/rds_keep_stopping.zip"
}

resource "aws_lambda_function" "lambda_rds_keep_stopping" {
  filename      = "${path.module}/lambda/rds_keep_stopping.zip"
  function_name = var.lambda_function_name
  description   = "continue to stop RDS by terraform module."
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler"

  source_code_hash = data.archive_file.lambda_archive_file.output_base64sha256

  runtime = "python3.9"
  timeout = 600

  environment {
    variables = {
      DB_MATCHER_NAMES = var.db_matcher_name
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda_cloudwatch_log_group]
}

resource "aws_cloudwatch_log_group" "lambda_cloudwatch_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "lambda_cloudwatch_event_start_rule" {
  name                = "terraform-rds-keep-stopping-start-rule"
  description         = "start RDS periodically by terraform module"
  schedule_expression = var.cloudwatch_start_schedule
}

resource "aws_cloudwatch_event_target" "lambda_cloudwatch_event_start_target" {
  rule      = aws_cloudwatch_event_rule.lambda_cloudwatch_event_start_rule.name
  target_id = "terraform-rds-keep-stopping-start-rule"
  arn       = aws_lambda_function.lambda_rds_keep_stopping.arn
  input     = "{\"command\":\"start\"}"
}

resource "aws_lambda_permission" "lambda_rds_keep_stopping_start_permission" {
  statement_id  = "AllowExecutionFromStartCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_rds_keep_stopping.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_cloudwatch_event_start_rule.arn
}

resource "aws_cloudwatch_event_rule" "lambda_cloudwatch_event_stop_rule" {
  name                = "terraform-rds-keep-stopping-stop-rule"
  description         = "stop RDS periodically by terraform module"
  schedule_expression = var.cloudwatch_stop_schedule
}

resource "aws_cloudwatch_event_target" "lambda_cloudwatch_event_stop_target" {
  rule      = aws_cloudwatch_event_rule.lambda_cloudwatch_event_stop_rule.name
  target_id = "terraform-rds-keep-stopping-stop-rule"
  arn       = aws_lambda_function.lambda_rds_keep_stopping.arn
  input     = "{\"command\":\"stop\"}"
}

resource "aws_lambda_permission" "lambda_rds_keep_stopping_stop_permission" {
  statement_id  = "AllowExecutionFromStopCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_rds_keep_stopping.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_cloudwatch_event_stop_rule.arn
}
