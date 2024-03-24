data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "send_message" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.sqs_queue_name}"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = local.s3_bucket_arns
    }
  }
}

resource "aws_sqs_queue" "this" {
  name                       = local.sqs_queue_name
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = local.visibility_timeout_seconds
  receive_wait_time_seconds  = 20
  policy                     = data.aws_iam_policy_document.send_message.json
}
