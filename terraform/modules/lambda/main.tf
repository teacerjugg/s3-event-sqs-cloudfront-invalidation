data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "create_invalidation" {
  statement {
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
    ]

    resources = local.cloudfront_distribution_arns
  }
}

data "aws_iam_policy_document" "sqs" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [
      var.sqs_queue_arn
    ]
  }
}

resource "aws_iam_policy" "sqs" {
  name        = local.receive_sqs_iam_policy_name
  description = "A policy for the SQS queue to receive and delete messages."
  policy      = data.aws_iam_policy_document.sqs.json
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "this" {
  name               = local.lambda_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  inline_policy {
    name   = "create-invalidation-policy"
    policy = data.aws_iam_policy_document.create_invalidation.json
  }
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "sqs" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.sqs.arn
}

resource "null_resource" "build" {
  triggers = {
    code_diff = join("", [
      for file in fileset(local.lambda_source_path, "*/*.rs") : filebase64("${local.lambda_source_path}/${file}")
    ])
  }

  provisioner "local-exec" {
    working_dir = local.lambda_source_path
    command     = "cargo lambda build --release"
  }
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = local.lambda_bin_path
  output_path = local.lambda_zip_path

  depends_on = [null_resource.build]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 3
}

resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name

  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  role                           = aws_iam_role.this.arn
  handler                        = local.lambda_bin_name
  runtime                        = "provided.al2023"
  timeout                        = 40
  reserved_concurrent_executions = 1

  environment {
    variables = {
      DISTRIBUTION_IDS = jsonencode(var.s3_bucket_cloudfront_map)
      QUEUE_URL        = var.sqs_queue_url
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
  ]
}

# resource "aws_lambda_event_source_mapping" "this" {
#   event_source_arn                   = var.sqs_queue_arn
#   function_name                      = aws_lambda_function.this.arn
#   batch_size                         = local.batch_size
#   maximum_batching_window_in_seconds = local.maximum_batching_window_in_seconds
# }
