# api-puts3object.tf

# API Gateway for s3
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

# API Gateway Method 
resource "aws_api_gateway_method" "s3_put_object_method" {
  rest_api_id   = aws_api_gateway_rest_api.s3_api.id
  resource_id   = aws_api_gateway_resource.s3_put_object_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "s3_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.s3_api.id
  resource_id             = aws_api_gateway_resource.s3_put_object_resource.id
  http_method             = aws_api_gateway_method.s3_put_object_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_put_s3.lambda_invoke_arn
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
