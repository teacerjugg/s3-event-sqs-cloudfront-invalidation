variable "s3_bucket_cloudfront_map" {
  description = "A map of S3 bucket name and CloudFront distribution ID."
  type        = map(string)
  nullable    = false
}

locals {
  s3_bucket_names = [
    for bucket_name, _ in var.s3_bucket_cloudfront_map : bucket_name
  ]
}
