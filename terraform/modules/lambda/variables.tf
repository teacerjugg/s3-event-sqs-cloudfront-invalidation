variable "s3_bucket_cloudfront_map" {
  description = "A map of S3 bucket name and CloudFront distribution ID."
  type        = map(string)
  nullable    = false
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue."
  type        = string
  nullable    = false
}

variable "sqs_queue_url" {
  description = "The URL of the SQS queue."
  type        = string
  nullable    = false
}

variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
  default     = "s3-event-sqs-clear-cloudfront-cache"
  nullable    = false
}

locals {
  receive_sqs_iam_policy_name = "s3-event-notification-sqs-policy"
  lambda_iam_role_name        = "s3-event-sqs-clear-cloudfront-cache-role"

  cloudfront_distribution_arns = [
    for bucket_name, distribution_id in var.s3_bucket_cloudfront_map : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${distribution_id}"
  ]

  lambda_bin_name     = "bootstrap"
  lambda_project_name = "s3-event-sqs-clear-cloudfront-cache"
  lambda_source_path  = "${path.module}/../../../${local.lambda_project_name}"
  lambda_bin_path     = "${local.lambda_source_path}/target/lambda/${local.lambda_project_name}/${local.lambda_bin_name}"
  lambda_zip_path     = "${local.lambda_bin_path}.zip"

  # batch_size                         = 10000
  # maximum_batching_window_in_seconds = 30
}
