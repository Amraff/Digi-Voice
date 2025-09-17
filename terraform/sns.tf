resource "aws_sns_topic" "sns_topic" {
  name         = "new_posts"
  display_name = "New posts"
}

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.convert_to_audio.arn

  depends_on = [aws_lambda_function.convert_to_audio]
}