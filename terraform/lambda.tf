# ---------------------------
# New Post Lambda
# ---------------------------
data "archive_file" "lambda_new_post" {
  type        = "zip"
  source_file = "${path.root}/../lambda/handler.py"
  output_path = "${path.root}/../deploy/handler.zip"
}

resource "aws_lambda_function" "new_posts_lambda" {
  function_name = "PostReader_NewPost"
  runtime       = "python3.13"
  role          = aws_iam_role.iam_role.arn
  memory_size   = var.memory_size_lambda
  timeout       = var.timeout_lambda

  handler          = "handler.lambda_handler"
  filename         = data.archive_file.lambda_new_post.output_path
  source_code_hash = data.archive_file.lambda_new_post.output_base64sha256

  environment {
    variables = {
      DB_TABLE_NAME = aws_dynamodb_table.table1.name
      SNS_TOPIC     = aws_sns_topic.sns_topic.arn
    }
  }
}

# ---------------------------
# Convert To Audio Lambda
# ---------------------------
data "archive_file" "lambda_convert_to_audio" {
  type        = "zip"
  source_file = "${path.root}/../lambda/convert_to_audio.py"
  output_path = "${path.root}/../deploy/convert_to_audio.zip"
}

resource "aws_lambda_function" "convert_to_audio" {
  function_name = "PostReader_ConvertToAudio"
  runtime       = "python3.13"
  role          = aws_iam_role.iam_role.arn
  memory_size   = var.memory_size_lambda
  timeout       = var.timeout_lambda

  handler          = "convert_to_audio.lambda_handler"
  filename         = data.archive_file.lambda_convert_to_audio.output_path
  source_code_hash = data.archive_file.lambda_convert_to_audio.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME   = var.bucket_name
      DB_TABLE_NAME = aws_dynamodb_table.table1.name
    }
  }
}

# ---------------------------
# Get Post Lambda
# ---------------------------
data "archive_file" "lambda_get_post" {
  type        = "zip"
  source_file = "${path.root}/../lambda/get_post.py"
  output_path = "${path.root}/../deploy/get_post.zip"
}

resource "aws_lambda_function" "get_post" {
  function_name = "PostReader_GetPost"
  runtime       = "python3.13"
  role          = aws_iam_role.iam_role.arn
  memory_size   = var.memory_size_lambda
  timeout       = var.timeout_lambda

  handler          = "get_post.lambda_handler"
  filename         = data.archive_file.lambda_get_post.output_path
  source_code_hash = data.archive_file.lambda_get_post.output_base64sha256

  environment {
    variables = {
      DB_TABLE_NAME = aws_dynamodb_table.table1.name
    }
  }
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
