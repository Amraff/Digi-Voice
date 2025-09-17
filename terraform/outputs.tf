# ---------------------------
# Outputs
# ---------------------------
output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.polly_api.id}.execute-api.${var.region}.amazonaws.com/prod"
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.voicebox_cdn.domain_name
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.voicebox_cdn.domain_name}"
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.voicebox_pool.id
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.voicebox_client.id
}

output "s3_website_url" {
  description = "S3 website URL"
  value       = "http://${aws_s3_bucket.website.bucket}.s3-website-${var.region}.amazonaws.com"
}

output "custom_domain_url" {
  description = "Custom domain URL"
  value       = "https://voicebox.rafftec.click"
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}