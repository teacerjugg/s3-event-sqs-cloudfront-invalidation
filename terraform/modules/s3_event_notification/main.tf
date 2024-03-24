resource "aws_s3_bucket_notification" "this" {
  for_each = toset(var.s3_bucket_names)

  bucket = each.key

  queue {
    queue_arn = var.sqs_queue_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

