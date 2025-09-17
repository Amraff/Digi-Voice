# ---------------------------
# Route 53 Hosted Zone
# ---------------------------
resource "aws_route53_zone" "main" {
  name = "rafftec.click"
  
  tags = {
    Name = "rafftec.click"
  }
}

# ---------------------------
# SSL Certificate for CloudFront
# ---------------------------
resource "aws_acm_certificate" "voicebox_cert" {
  provider          = aws.us_east_1  # CloudFront requires certificates in us-east-1
  domain_name       = "voicebox.rafftec.click"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------
# Certificate Validation
# ---------------------------
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.voicebox_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "voicebox_cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.voicebox_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ---------------------------
# Route 53 Record for CloudFront (temporarily disabled)
# ---------------------------
# resource "aws_route53_record" "voicebox" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "voicebox.rafftec.click"
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.voicebox_cdn.domain_name
#     zone_id                = aws_cloudfront_distribution.voicebox_cdn.hosted_zone_id
#     evaluate_target_health = false
#   }
# }