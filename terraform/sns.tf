# ---------------------------
# SNS Topic
# ---------------------------
resource "aws_sns_topic" "sns_topic" {
  name = "polly-app-topic"
}

# ---------------------------
# SNS Subscription (Lambda)
# ---------------------------
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.convert_to_audio.arn

  depends_on = [aws_lambda_function.convert_to_audio]
}

# ---------------------------
# Allow SNS to invoke ConvertToAudio Lambda
# Temporarily disabled - causing deployment issues
# ---------------------------
# resource "aws_lambda_permission" "allow_sns" {
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.convert_to_audio.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.sns_topic.arn
# }