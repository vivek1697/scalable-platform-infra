locals {
  name        = "${var.project}-${var.environment}"
  bucket_name = var.bucket_name != "" ? var.bucket_name : "${var.project}-${var.environment}-frontend"

  s3_origin_id  = "s3-${local.bucket_name}"
  api_origin_id = "api"

  # Gate the API origin on a static flag (not the domain value), because the
  # ALB DNS name isn't known at plan time and for_each/count must be known.
  api_enabled = var.enable_api_origin
  api_origin  = var.api_origin_domain_name
}
