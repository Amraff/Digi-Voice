# ------------------------------
# NEW REST API - No Authentication
# ------------------------------
resource "aws_api_gateway_rest_api" "voicebox_api" {
  name        = "VoiceBox API No Auth"
  description = "API for text-to-speech conversion - No Authentication"
}

# ------------------------------
# Direct Audio Lambda
# ------------------------------
resource "aws_lambda_function" "direct_audio" {
  filename         = "../lambda/direct_audio.zip"
  function_name    = "DirectAudio"
  role            = aws_iam_role.iam_role.arn
  handler         = "direct_audio.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.website.bucket
    }
  }
}

# ------------------------------
# /direct-audio endpoint
# ------------------------------
resource "aws_api_gateway_resource" "direct_audio" {
  rest_api_id = aws_api_gateway_rest_api.voicebox_api.id
  parent_id   = aws_api_gateway_rest_api.voicebox_api.root_resource_id
  path_part   = "direct-audio"
}

resource "aws_api_gateway_method" "direct_audio_method" {
  rest_api_id   = aws_api_gateway_rest_api.voicebox_api.id
  resource_id   = aws_api_gateway_resource.direct_audio.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "direct_audio_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.voicebox_api.id
  resource_id             = aws_api_gateway_resource.direct_audio.id
  http_method             = aws_api_gateway_method.direct_audio_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.direct_audio.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_direct_audio" {
  statement_id  = "AllowDirectAudioInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.direct_audio.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.voicebox_api.execution_arn}/*/*"
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
# /get-post
# ------------------------------
resource "aws_api_gateway_resource" "get_post_v2" {
  rest_api_id = aws_api_gateway_rest_api.voicebox_api.id
  parent_id   = aws_api_gateway_rest_api.voicebox_api.root_resource_id
  path_part   = "get-post"
}

resource "aws_api_gateway_method" "get_post_method_v2" {
  rest_api_id   = aws_api_gateway_rest_api.voicebox_api.id
  resource_id   = aws_api_gateway_resource.get_post_v2.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_post_lambda_v2" {
  rest_api_id             = aws_api_gateway_rest_api.voicebox_api.id
  resource_id             = aws_api_gateway_resource.get_post_v2.id
  http_method             = aws_api_gateway_method.get_post_method_v2.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_post.invoke_arn
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
    aws_api_gateway_integration.direct_audio_lambda,
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
  statement_id  = "AllowNewPostInvokeV3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.new_posts_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.voicebox_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_voices_v2" {
  statement_id  = "AllowVoicesInvokeV3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.voices.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.voicebox_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_get_post_v2" {
  statement_id  = "AllowGetPostInvokeV3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_post.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.voicebox_api.execution_arn}/*/*"
}