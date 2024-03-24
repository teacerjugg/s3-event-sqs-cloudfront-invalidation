data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "invoke_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      var.lambda_function_arn
    ]
  }
}

resource "aws_iam_role" "this" {
  name               = local.scheduler_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  inline_policy {
    name   = "invoke-lambda-policy"
    policy = data.aws_iam_policy_document.invoke_lambda.json
  }
}

resource "aws_scheduler_schedule_group" "this" {
  count = var.schedule_group_name != null ? 1 : 0
  name  = var.schedule_group_name
}

resource "aws_scheduler_schedule" "this" {
  name                         = local.scheduler_name
  group_name                   = var.schedule_group_name != null ? aws_scheduler_schedule_group.this[0].name : "default"
  description                  = "A schedule to invoke the Lambda function."
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = var.lambda_function_arn
    role_arn = aws_iam_role.this.arn
  }
}
