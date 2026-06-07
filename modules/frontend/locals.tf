locals {
  name        = "${var.project}-${var.environment}"
  bucket_name = var.bucket_name != "" ? var.bucket_name : "${var.project}-${var.environment}-frontend"

  s3_origin_id  = "s3-${local.bucket_name}"
  api_origin_id = "api"

  # Normalize a possibly-null API origin and decide whether to wire it up.
  api_origin  = var.api_origin_domain_name == null ? "" : var.api_origin_domain_name
  api_enabled = local.api_origin != ""
}
