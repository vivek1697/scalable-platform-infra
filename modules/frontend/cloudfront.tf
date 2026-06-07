# Origin Access Control lets CloudFront read the private S3 bucket (SigV4).
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.name}-frontend-oac"
  description                       = "OAC for ${local.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = var.default_root_object
  price_class         = var.price_class
  comment             = "${local.name} frontend"

  # S3 origin for static assets.
  origin {
    origin_id                = local.s3_origin_id
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # Optional API origin (e.g. the web ALB) for dynamic requests.
  dynamic "origin" {
    for_each = local.api_enabled ? [1] : []

    content {
      origin_id   = local.api_origin_id
      domain_name = local.api_origin

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Static assets: cache aggressively.
  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # API requests: forward to the ALB origin, no caching.
  dynamic "ordered_cache_behavior" {
    for_each = local.api_enabled ? [1] : []

    content {
      path_pattern           = var.api_path_pattern
      target_origin_id       = local.api_origin_id
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD"]

      forwarded_values {
        query_string = true
        headers      = ["*"]

        cookies {
          forward = "all"
        }
      }

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0
    }
  }

  # SPA routing: serve the app shell for client-side routes / missing keys.
  dynamic "custom_error_response" {
    for_each = var.spa_routing ? toset([403, 404]) : toset([])

    content {
      error_code         = custom_error_response.value
      response_code      = 200
      response_page_path = "/${var.default_root_object}"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
