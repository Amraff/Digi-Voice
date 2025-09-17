# ---------------------------
# New Post Lambda
# ---------------------------
resource "aws_lambda_function" "new_posts_lambda" {
  function_name = "PostReader_NewPost"
  runtime       = "python3.12"
  role          = aws_iam_role.iam_role.arn
  memory_size   = 128
  timeout       = 30

  handler = "handler.lambda_handler"
  s3_bucket = var.bucket_name
  s3_key    = "deploy/handler.zip"
}

# ---------------------------
# Convert To Audio Lambda
# ---------------------------
resource "aws_lambda_function" "convert_to_audio" {
  function_name = "PostReader_ConvertToAudio"
  runtime       = "python3.12"
  role          = aws_iam_role.iam_role.arn
  memory_size   = 128
  timeout       = 30

  handler = "convert_to_audio.lambda_handler"
  s3_bucket = var.bucket_name
  s3_key    = "deploy/convert_to_audio.zip"
}

# ---------------------------
# Get Post Lambda
# ---------------------------
resource "aws_lambda_function" "get_post" {
  function_name = "PostReader_GetPost"
  runtime       = "python3.12"
  role          = aws_iam_role.iam_role.arn
  memory_size   = 128
  timeout       = 30

  handler = "get_post.lambda_handler"
  s3_bucket = var.bucket_name
  s3_key    = "deploy/get_post.zip"
}

# ---------------------------
# Voices Lambda
# ---------------------------
resource "aws_lambda_function" "voices" {
  function_name = "PostReader_Voices"
  runtime       = "python3.12"
  role          = aws_iam_role.iam_role.arn
  memory_size   = 128
  timeout       = 30

  handler = "voices.lambda_handler"
  s3_bucket = var.bucket_name
  s3_key    = "deploy/voices.zip"
}

resource "aws_lambda_permission" "api_gateway_new_post" {
  statement_id  = "AllowNewPostInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.new_posts_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.polly_api.execution_arn}/*/POST/new_post"
}

resource "aws_lambda_permission" "api_gateway_get_post" {
  statement_id  = "AllowGetPostInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_post.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.polly_api.execution_arn}/*/GET/get-post"
}

resource "aws_lambda_permission" "api_gateway_voices" {
  statement_id  = "AllowVoicesInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.voices.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.polly_api.execution_arn}/*/GET/voices"
}

# ---------------------------
# CloudWatch Log Groups for Lambdas
# ---------------------------
resource "aws_cloudwatch_log_group" "new_post" {
  name              = "/aws/lambda/PostReader_NewPost"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [name]
  }

  depends_on = [aws_lambda_function.new_posts_lambda]
}

resource "aws_cloudwatch_log_group" "convert_to_audio" {
  name              = "/aws/lambda/PostReader_ConvertToAudio"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [name]
  }

  depends_on = [aws_lambda_function.convert_to_audio]
}

resource "aws_cloudwatch_log_group" "get_post" {
  name              = "/aws/lambda/PostReader_GetPost"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [name]
  }

  depends_on = [aws_lambda_function.get_post]
}

resource "aws_cloudwatch_log_group" "voices" {
  name              = "/aws/lambda/PostReader_Voices"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [name]
  }

  depends_on = [aws_lambda_function.voices]
}
