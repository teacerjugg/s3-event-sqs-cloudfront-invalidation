variable "s3_bucket_names" {
  description = "The names of the S3 bucket"
  type        = list(string)
  nullable    = false
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue."
  type        = string
  nullable    = false
}
