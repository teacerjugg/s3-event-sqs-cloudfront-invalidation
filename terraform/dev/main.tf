provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project     = "test-project"
      Environment = "development"
      ManagedBy   = "Terraform"
    }
  }
}

module "sqs" {
  source = "../modules/sqs"

  s3_bucket_names = local.s3_bucket_names
  # 10時間
  message_retention_seconds = 60 * 60 * 10
}

module "s3_event_notification" {
  source = "../modules/s3_event_notification"

  s3_bucket_names = local.s3_bucket_names
  sqs_queue_arn   = module.sqs.sqs_queue_arn
}

module "lambda" {
  source = "../modules/lambda"

  lambda_function_name     = "s3-event-sqs-clear-cloudfront-cache"
  s3_bucket_cloudfront_map = var.s3_bucket_cloudfront_map
  sqs_queue_arn            = module.sqs.sqs_queue_arn
  sqs_queue_url            = module.sqs.sqs_queue_url
}

module "scheduler" {
  source = "../modules/scheduler"

  lambda_function_arn = module.lambda.lambda_function_arn
  schedule_group_name = "test"
  # 平日の8時から22時59分までの間に毎分実行
  schedule_expression = "cron(* 8-22 ? * MON-FRI *)"
}
