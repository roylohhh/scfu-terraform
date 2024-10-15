# main.tf

provider "aws" {
  region = "ap-southeast-2"
}

# Call the Lambda module for DynamoDB interaction
module "lambda_dynamodb" {
  source                = "./modules/lambda-module"
  function_name         = "LambdaWriteDynamoDBFunction"
  handler               = "putitem.putFormItemHandler"
  runtime               = "nodejs20.x"
  filename              = "${path.module}/lambda/build/putitem.zip"
  lambda_exec_role_arn  = aws_iam_role.lambda_exec_role.arn
  environment_variables = {
    PARTICIPANT_CONSENT_TABLE = "consent_form_table"
  }
  timeout               = 15
}

# Call the Lambda module for S3 interaction
module "lambda_put_s3" {
  source                = "./modules/lambda-module"
  function_name         = "LambdaPutS3Object"
  handler               = "puts3object.handler"
  runtime               = "nodejs20.x"
  filename              = "${path.module}/lambda/build/puts3object.zip"
  lambda_exec_role_arn  = aws_iam_role.lambda_exec_role.arn
  environment_variables = {
    S3_BUCKET_NAME = aws_s3_bucket.csiro_consent_forms.bucket
  }
  timeout               = 15
}
