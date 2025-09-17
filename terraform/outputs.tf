output "api_base_url" {
  value = "https://${aws_api_gateway_rest_api.polly_api.id}.execute-api.${var.region}.amazonaws.com/prod"
}
