# ---------------------------
# Cognito User Pool
# ---------------------------
resource "aws_cognito_user_pool" "voicebox_pool" {
  name = "voicebox-users"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "VoiceBox - Verify your account"
    email_message        = "Your verification code is {####}"
  }

  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable           = true
  }
}

# ---------------------------
# Cognito User Pool Client
# ---------------------------
resource "aws_cognito_user_pool_client" "voicebox_client" {
  name         = "voicebox-client"
  user_pool_id = aws_cognito_user_pool.voicebox_pool.id

  generate_secret = false
  
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
}

# ---------------------------
# Cognito Authorizer for API Gateway
# ---------------------------
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "voicebox-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.polly_api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.voicebox_pool.arn]
}