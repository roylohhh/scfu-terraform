# main.tf

provider "aws" {
  region = "ap-southeast-2"
}

# Call the Lambda module for DynamoDB interaction
module "lambda_dynamodb" {
  source = "./modules/lambda-module"

  function_name        = "LambdaWriteDynamoDBFunction"
  handler              = "putitem.putFormItemHandler"
  runtime              = "nodejs20.x"
  filename             = "${path.module}/lambda/putitem.zip"
  lambda_exec_role_arn = aws_iam_role.lambda_exec_role.arn
  environment_variables = {
    PARTICIPANT_CONSENT_TABLE = "consent_form_table"
  }
  layers = [aws_lambda_layer_version.my_layer.arn]
}

# Call lambda module for S3 interaction
module "lambda_put_s3" {
  source = "./modules/lambda-module"

  function_name        = "LambdaPutS3Object"
  handler              = "puts3object.handler"
  runtime              = "nodejs20.x"
  filename             = "${path.module}/lambda/puts3object.zip"
  lambda_exec_role_arn = aws_iam_role.lambda_exec_role.arn
  environment_variables = {
    S3_BUCKET_NAME = aws_s3_bucket.csiro_consent_forms.bucket
  }
  layers = [aws_lambda_layer_version.my_layer.arn]
}

# DynamoDB Api Gateway CORS Module
module "DynamoDB_api_cors" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.dynamodb_api.id
  api_resource_id = aws_api_gateway_resource.put_item_resource.id
}

# S3 Api Gateway CORS Module
module "S3_api_cors" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.s3_api.id
  api_resource_id = aws_api_gateway_resource.s3_put_object_resource.id
}