# api.tf

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "LambdaDynamoDBAPI"
  description = "API Gateway for DynamoDB Lambda function"
}

# Cognito JWT Authorizer
resource "aws_api_gatewayv2_authorizer" "http_api_authorizer" {
  api_id            = aws_api_gatewayv2_api.http_api.id
  name              = "JwtAuthorizer"
  authorizer_type   = "JWT"
  identity_source   = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.user_pool_client.id] # This is correct
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
  }
}

# API Gateway Resource
resource "aws_api_gateway_resource" "put_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "put-item"
}

# API Gateway Method
resource "aws_api_gateway_method" "put_item_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.put_item_resource.id
  http_method   = "POST"
  authorization = aws_api_gatewayv2_authorizer.http_api_authorizer.id  # Attach the authorizer
}

# API Gateway Integration (Connect POST /put-item to the Lambda function)
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.put_item_resource.id
  http_method             = aws_api_gateway_method.put_item_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_dynamodb.lambda_invoke_arn
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_dynamodb.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "aws_api_gateway_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}
