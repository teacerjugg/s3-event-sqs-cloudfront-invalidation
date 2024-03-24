variable "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  type        = string
  nullable    = false
}

variable "schedule_group_name" {
  description = "The name of the schedule group."
  type        = string
  nullable    = true
}

variable "schedule_expression" {
  description = "The schedule expression."
  type        = string
  # 平日の8時から22時59分までの間に毎分実行
  default  = "cron(* 8-22 ? * MON-FRI *)"
  nullable = true
}

locals {
  scheduler_name          = "s3-event-sqs-clear-cloudfront-cache-scheduler"
  scheduler_iam_role_name = "s3-event-sqs-clear-cloudfront-cache-scheduler-role"
}
