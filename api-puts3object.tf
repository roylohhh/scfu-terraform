# API Gateway for S3
resource "aws_api_gateway_rest_api" "s3_api" {
  name        = "LambdaS3API"
  description = "API Gateway for S3 Lambda function"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "s3_put_object_resource" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  parent_id   = aws_api_gateway_rest_api.s3_api.root_resource_id
  path_part   = "put-object"
}
# Cognito User Pool Authorizer
resource "aws_api_gateway_authorizer" "s3_authorizer" {
  name        = "s3_authorizer"
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  type        = "COGNITO_USER_POOLS"
  provider_arns = [
    aws_cognito_user_pool.user_pool.arn
  ]
}


# API Gateway OPTIONS Method for CORS (Preflight request)
resource "aws_api_gateway_method" "s3_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.s3_api.id
  resource_id   = aws_api_gateway_resource.s3_put_object_resource.id
  http_method   = "OPTIONS"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.s3_authorizer.id
}

# API Gateway OPTIONS Method Response (CORS)
resource "aws_api_gateway_method_response" "s3_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.s3_put_object_resource.id
  http_method = aws_api_gateway_method.s3_options_method.http_method
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
    aws_api_gateway_method.s3_options_method
  ]
}

# API Gateway Integration for OPTIONS (CORS)
resource "aws_api_gateway_integration" "s3_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.s3_put_object_resource.id
  http_method = aws_api_gateway_method.s3_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [
    aws_api_gateway_method.s3_options_method
  ]
}

# API Gateway Integration Response for OPTIONS (CORS)
resource "aws_api_gateway_integration_response" "s3_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.s3_put_object_resource.id
  http_method = aws_api_gateway_method.s3_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.s3_options_method_response
  ]
}

# API Gateway Method (POST) for S3 Lambda Integration
resource "aws_api_gateway_method" "s3_put_object_method" {
  rest_api_id   = aws_api_gateway_rest_api.s3_api.id
  resource_id   = aws_api_gateway_resource.s3_put_object_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.s3_authorizer.id
}

# API Gateway Method Response for POST (CORS)
resource "aws_api_gateway_method_response" "s3_put_object_method_response" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.s3_put_object_resource.id
  http_method = aws_api_gateway_method.s3_put_object_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  depends_on = [
    aws_api_gateway_method.s3_put_object_method
  ]
}

# API Gateway Integration for POST
resource "aws_api_gateway_integration" "s3_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.s3_api.id
  resource_id             = aws_api_gateway_resource.s3_put_object_resource.id
  http_method             = aws_api_gateway_method.s3_put_object_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_put_s3.lambda_invoke_arn

  depends_on = [
    aws_api_gateway_method.s3_put_object_method
  ]
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "s3_apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeS3"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_put_s3.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.s3_api.execution_arn}/*/*"
}

# Deploy the API Gateway for S3 Lambda
resource "aws_api_gateway_deployment" "s3_api_gateway_deployment" {
  depends_on = [aws_api_gateway_integration.s3_lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  stage_name  = "prod"
}
