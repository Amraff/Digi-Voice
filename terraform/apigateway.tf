resource "aws_api_gateway_rest_api" "polly_api" {
  name        = "Polly API"
  description = "API for text-to-speech conversion using AWS Polly"
}
resource "aws_api_gateway_resource" "new_post" {
  rest_api_id = aws_api_gateway_rest_api.polly_api.id
  parent_id   = aws_api_gateway_rest_api.polly_api.root_resource_id
  path_part   = "new_post"
}
resource "aws_api_gateway_method" "post_new" {
  rest_api_id   = aws_api_gateway_rest_api.polly_api.id
  resource_id   = aws_api_gateway_resource.new_post.id
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "post_new_lambda" {
  rest_api_id = aws_api_gateway_rest_api.polly_api.id
  resource_id = aws_api_gateway_resource.new_post.id
  http_method = aws_api_gateway_method.post_new.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.new_posts_lambda.invoke_arn

  depends_on = [aws_lambda_function.new_posts_lambda]
}


resource "aws_api_gateway_resource" "get_post" {
  rest_api_id = aws_api_gateway_rest_api.polly_api.id
  parent_id   = aws_api_gateway_rest_api.polly_api.root_resource_id
  path_part   = "get-post"
}

resource "aws_api_gateway_method" "get_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.polly_api.id
  resource_id   = aws_api_gateway_resource.get_post.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.polly_api.id
  resource_id             = aws_api_gateway_resource.get_post.id
  http_method             = aws_api_gateway_method.get_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_post.invoke_arn
}

resource "aws_api_gateway_deployment" "deploy" {
  depends_on = [
    aws_api_gateway_integration.post_new_lambda,
    aws_api_gateway_integration.get_post_lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.polly_api.id
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.polly_api.id
  stage_name    = "prod"
}

resource "aws_api_gateway_method_response" "post_response" {
  rest_api_id = aws_api_gateway_rest_api.polly_api.id
  resource_id = aws_api_gateway_resource.new_post.id
  http_method = "POST"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "get_response" {
  rest_api_id = aws_api_gateway_rest_api.polly_api.id
  resource_id = aws_api_gateway_resource.get_post.id
  http_method = "GET"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# resource "aws_api_gateway_integration_response" "post_integration_response" {
#   rest_api_id = aws_api_gateway_rest_api.polly_api.id
#   resource_id = aws_api_gateway_resource.new_post.id
#   http_method = aws_api_gateway_method.post_new.http_method
#   status_code = aws_api_gateway_method_response.post_response.status_code

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin" = "'*'"
#   }
# }

# resource "aws_api_gateway_integration_response" "get_integration_response" {
#   rest_api_id = aws_api_gateway_rest_api.polly_api.id
#   resource_id = aws_api_gateway_resource.get_post.id
#   http_method = aws_api_gateway_method.get_post_method.http_method
#   status_code = aws_api_gateway_method_response.get_response.status_code

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin" = "'*'"
#   }
# }


resource "aws_api_gateway_method" "options_new_post" {
  rest_api_id   = aws_api_gateway_rest_api.polly_api.id
  resource_id   = aws_api_gateway_resource.new_post.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_new_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.polly_api.id
  resource_id = aws_api_gateway_resource.new_post.id
  http_method = "OPTIONS"
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  depends_on = [aws_api_gateway_method.options_new_post]
}

resource "aws_api_gateway_method_response" "options_new_post_response" {
  rest_api_id = aws_api_gateway_rest_api.polly_api.id
  resource_id = aws_api_gateway_resource.new_post.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
  depends_on = [aws_api_gateway_method.options_new_post]
}

resource "aws_api_gateway_integration_response" "options_new_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.polly_api.id
  resource_id = aws_api_gateway_resource.new_post.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_new_post_integration, aws_api_gateway_method.options_new_post]
}