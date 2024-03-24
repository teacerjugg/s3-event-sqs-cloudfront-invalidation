variable "s3_bucket_names" {
  description = "The names of the S3 bucket"
  type        = list(string)
  nullable    = false
}

variable "message_retention_seconds" {
  description = "The number of seconds to retain a message."
  type        = number
  default     = 60 * 60 * 10
  nullable    = true
}

locals {
  // lambda timeout seconds * 6 + maximum batching windows in seconds
  // NOTE: https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/with-sqs.html
  visibility_timeout_seconds = 40 * 6 + 30

  sqs_queue_name = "s3-event-notification-create-invalidation-queue"
  s3_bucket_arns = [
    for bucket_name in var.s3_bucket_names : "arn:aws:s3:::${bucket_name}"
  ]
}
