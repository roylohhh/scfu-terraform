# API Gateway for DynamoDB
resource "aws_api_gateway_rest_api" "dynamodb_api" {
  name        = "LambdaDynamoDBAPI"
  description = "API Gateway for DynamoDB Lambda function"
}

# API Gateway Resource 
resource "aws_api_gateway_resource" "put_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.dynamodb_api.id
  parent_id   = aws_api_gateway_rest_api.dynamodb_api.root_resource_id
  path_part   = "put-item"
}

# API Gateway OPTIONS Method for CORS
resource "aws_api_gateway_method" "dynamodb_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.dynamodb_api.id
  resource_id   = aws_api_gateway_resource.put_item_resource.id
  http_method   = "OPTIONS"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.dynamodb_authorizer.id
}

# API Gateway OPTIONS Method Response (CORS)
resource "aws_api_gateway_method_response" "dynamodb_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.dynamodb_api.id
  resource_id = aws_api_gateway_resource.put_item_resource.id
  http_method = aws_api_gateway_method.dynamodb_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    aws_api_gateway_method.dynamodb_options_method
  ]
}

# API Gateway Integration for OPTIONS (CORS)
resource "aws_api_gateway_integration" "dynamodb_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.dynamodb_api.id
  resource_id = aws_api_gateway_resource.put_item_resource.id
  http_method = aws_api_gateway_method.dynamodb_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [
    aws_api_gateway_method.dynamodb_options_method
  ]
}

# API Gateway Integration Response for OPTIONS (CORS)
resource "aws_api_gateway_integration_response" "dynamodb_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.dynamodb_api.id
  resource_id = aws_api_gateway_resource.put_item_resource.id
  http_method = aws_api_gateway_method.dynamodb_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.dynamodb_options_method_response
  ]
}



# Cognito User Pool Authorizer
resource "aws_api_gateway_authorizer" "dynamodb_authorizer" {
  name = "dynamodb_authorizer"
  rest_api_id = aws_api_gateway_rest_api.dynamodb_api.id
  type = "COGNITO_USER_POOLS"
  provider_arns = [
    aws_cognito_user_pool.user_pool.arn
  ]
}

# API Gateway POST Method (for DynamoDB Lambda Integration)
resource "aws_api_gateway_method" "put_item_method" {
  rest_api_id   = aws_api_gateway_rest_api.dynamodb_api.id
  resource_id   = aws_api_gateway_resource.put_item_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.dynamodb_authorizer.id
}

# API Gateway Integration (Connect POST /put-item to the Lambda function)
resource "aws_api_gateway_integration" "dynamodb_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.dynamodb_api.id
  resource_id             = aws_api_gateway_resource.put_item_resource.id
  http_method             = aws_api_gateway_method.put_item_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_dynamodb.lambda_invoke_arn
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "dynamodb_apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_dynamodb.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.dynamodb_api.execution_arn}/*/*"
}

# Deploy the API Gateway  
resource "aws_api_gateway_deployment" "dynamodb_api_gateway_deployment" {
  depends_on = [aws_api_gateway_integration.dynamodb_lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.dynamodb_api.id
  stage_name  = "prod"
}
