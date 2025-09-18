# ------------------------------
# NEW REST API - No Authentication
# ------------------------------
resource "aws_api_gateway_rest_api" "voicebox_api" {
  name        = "VoiceBox API No Auth"
  description = "API for text-to-speech conversion - No Authentication"
}

# ------------------------------
# /new_post
# ------------------------------
resource "aws_api_gateway_resource" "new_post_v2" {
  rest_api_id = aws_api_gateway_rest_api.voicebox_api.id
  parent_id   = aws_api_gateway_rest_api.voicebox_api.root_resource_id
  path_part   = "new_post"
}

resource "aws_api_gateway_method" "post_new_v2" {
  rest_api_id   = aws_api_gateway_rest_api.voicebox_api.id
  resource_id   = aws_api_gateway_resource.new_post_v2.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_new_lambda_v2" {
  rest_api_id             = aws_api_gateway_rest_api.voicebox_api.id
  resource_id             = aws_api_gateway_resource.new_post_v2.id
  http_method             = aws_api_gateway_method.post_new_v2.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.new_posts_lambda.invoke_arn
}

# ------------------------------
# /voices
# ------------------------------
resource "aws_api_gateway_resource" "voices_v2" {
  rest_api_id = aws_api_gateway_rest_api.voicebox_api.id
  parent_id   = aws_api_gateway_rest_api.voicebox_api.root_resource_id
  path_part   = "voices"
}

resource "aws_api_gateway_method" "voices_method_v2" {
  rest_api_id   = aws_api_gateway_rest_api.voicebox_api.id
  resource_id   = aws_api_gateway_resource.voices_v2.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "voices_lambda_v2" {
  rest_api_id             = aws_api_gateway_rest_api.voicebox_api.id
  resource_id             = aws_api_gateway_resource.voices_v2.id
  http_method             = aws_api_gateway_method.voices_method_v2.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.voices.invoke_arn
}

# ------------------------------
# Deployment & Stage
# ------------------------------
resource "aws_api_gateway_deployment" "deploy_v2_clean" {
  depends_on = [
    aws_api_gateway_integration.post_new_lambda_v2,
    aws_api_gateway_integration.voices_lambda_v2
  ]

  rest_api_id = aws_api_gateway_rest_api.voicebox_api.id
  
  triggers = {
    redeployment = timestamp()
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod_v2" {
  deployment_id = aws_api_gateway_deployment.deploy_v2_clean.id
  rest_api_id   = aws_api_gateway_rest_api.voicebox_api.id
  stage_name    = "prod"
}

# ------------------------------
# Lambda Permissions
# ------------------------------
resource "aws_lambda_permission" "api_gateway_new_post_v2" {
  statement_id  = "AllowNewPostInvokeV2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.new_posts_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.voicebox_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_voices_v2" {
  statement_id  = "AllowVoicesInvokeV2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.voices.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.voicebox_api.execution_arn}/*/*"
}