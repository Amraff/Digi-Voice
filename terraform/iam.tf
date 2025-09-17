resource "aws_iam_policy" "iam_policy" {
  name       = "lambda_functions"
  depends_on = [aws_dynamodb_table.table1, aws_s3_bucket.my_bucket, aws_sns_topic.sns_topic]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "PollyAndLogs",
        Effect = "Allow",
        Action = [
          "polly:SynthesizeSpeech",
          "polly:DescribeVoices",      # ✅ Needed for voices.py
          "s3:GetBucketLocation",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Sid    = "DynamoDB",
        Effect = "Allow",
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ],
        Resource = aws_dynamodb_table.table1.arn
      },
      {
        Sid    = "S3",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation"
        ],
        Resource = "${aws_s3_bucket.my_bucket.arn}/*"
      },
      {
        Sid    = "SNS",
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.sns_topic.arn
      }
    ]
  })
}

resource "aws_iam_role" "iam_role" {
  name = "lambda_functions_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach custom inline policy
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.iam_policy.arn
}

# Attach AWS managed logging policy
resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
