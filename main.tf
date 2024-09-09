# main.tf
  
provider "aws" {
    region = "ap-southeast-2"
}

# Lambda function for DynamoDB
resource "aws_lambda_function" "lambda_dynamodb" {
  filename      = "${path.module}/lambda/putitem.zip"
  function_name = "LambdaWriteDynamoDBFunction"
  role          = aws_iam_role.lambda_exec_role.arn  
  handler       = "putitem.putItemHandler"
  runtime       = "nodejs20.x"  # Updated runtime to the latest supported version for Node.js

  source_code_hash = filebase64sha256("${path.module}/lambda/putitem.zip")

  environment {
    variables = {
      DynamoDB_Table = "consent_form_table"
    }
  }

  layers = [
    aws_lambda_layer_version.my_layer.arn
  ]
}

# Upload the Lambda layer zip to S3
resource "aws_s3_bucket_object" "lambda_layer_object" {
  bucket = aws_s3_bucket.lambda_layer_bucket.bucket
  key    = "nodejs.zip"
  source = "${path.module}/lambda-layer/nodejs.zip" # Local path to your layer zip file
}

# Create the Lambda layer
resource "aws_lambda_layer_version" "my_layer" {
  layer_name          = "my-layer"
  s3_bucket           = aws_s3_bucket.lambda_layer_bucket.bucket
  s3_key              = aws_s3_bucket_object.lambda_layer_object.key
  compatible_runtimes = ["nodejs20.x"]
  description         = "Layer containing Node.js libraries for Lambda functions"
}

# API Gateway 
resource "aws_api_gateway_rest_api" "api" {
  name = "LambdaDynamoDBAPI"
  description = "API Gateway for DynamoDB Lambda function"
}

# API Gateway Resource 
resource "aws_api_gateway_resource" "put_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  path_part = "put-item" 
}

# API Gateway Method 
resource "aws_api_gateway_method" "put_item_method" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.put_item_resource.id
  http_method = "POST"
  authorization = "NONE"
}

# API Gateway Integration (Connect POST /put-item to the Lambda function)
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.put_item_resource.id
  http_method = aws_api_gateway_method.put_item_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.lambda_dynamodb.invoke_arn
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_dynamodb.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Deploy the API Gateway  
resource "aws_api_gateway_deployment" "aws_api_gateway_deployment" {
  depends_on = [ aws_api_gateway_integration.lambda_integration ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "prod"
}
