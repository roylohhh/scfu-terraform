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

