resource "aws_dynamodb_table" "table1" {
  name         = "posts"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Name = "text-to-speech"
  }
}