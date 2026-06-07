output "bucket_name" {
  description = "Name of the static-site S3 bucket (upload the React build here)."
  value       = aws_s3_bucket.site.bucket
}

output "bucket_arn" {
  description = "ARN of the static-site S3 bucket."
  value       = aws_s3_bucket.site.arn
}

output "distribution_id" {
  description = "CloudFront distribution ID (for cache invalidations)."
  value       = aws_cloudfront_distribution.site.id
}

output "distribution_domain_name" {
  description = "CloudFront domain name users hit (e.g. dxxxx.cloudfront.net)."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.site.arn
}
