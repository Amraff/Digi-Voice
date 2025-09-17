resource "aws_lambda_function" "new_posts_lambda" {
  function_name = "PostReader_NewPost"
  runtime       = "python3.13"
  role          = aws_iam_role.iam_role.arn
  memory_size   = var.memory_size_lambda
  timeout       = var.timeout_lambda

  handler          = "handler.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DB_TABLE_NAME = aws_dynamodb_table.table1.name
      SNS_TOPIC     = aws_sns_topic.sns_topic.arn
    }
  }
}
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.source_file_lambda_new_post
  output_path = "${path.module}/lambda_function_new_post.zip"
}


resource "aws_lambda_function" "convert_to_audio" {
  function_name = "PostReader_ConvertToAudio"
  runtime       = "python3.13"
  role          = aws_iam_role.iam_role.arn
  handler       = "convert_to_audio.lambda_handler"
  memory_size   = var.memory_size_lambda
  timeout       = var.timeout_lambda

  filename         = data.archive_file.lambda_convert_to_audio_zip.output_path
  source_code_hash = data.archive_file.lambda_convert_to_audio_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME   = var.bucket_name
      DB_TABLE_NAME = aws_dynamodb_table.table1.name
    }
  }
}
resource "aws_lambda_permission" "allow_sns_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.convert_to_audio.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic.arn

  depends_on = [aws_sns_topic_subscription.sns_topic_subscription]

}
data "archive_file" "lambda_convert_to_audio_zip" {
  type        = "zip"
  source_file = var.source_file_lambda_convert_to_audio
  output_path = "${path.module}/lambda_function_convert_to_audio.zip"
}


resource "aws_lambda_function" "get_post" {
  function_name = "PostReader_GetPost"
  runtime       = "python3.13"
  role          = aws_iam_role.iam_role.arn
  handler       = "get_post.lambda_handler"
  memory_size   = var.memory_size_lambda
  timeout       = var.timeout_lambda

  filename         = data.archive_file.get_post_zip.output_path
  source_code_hash = data.archive_file.get_post_zip.output_base64sha256

  environment {
    variables = {
      DB_TABLE_NAME = aws_dynamodb_table.table1.name
    }
  }
}

data "archive_file" "get_post_zip" {
  type        = "zip"
  source_file = var.source_file_lambda_get_post
  output_path = "${path.module}/get_post.zip"
}

resource "aws_lambda_permission" "api_gateway_new_post" {
  statement_id  = "AllowNewPostInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.new_posts_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.polly_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_get_post" {
  statement_id  = "AllowGetPostInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_post.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.polly_api.execution_arn}/*/*"
}
