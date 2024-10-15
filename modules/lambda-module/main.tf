resource "aws_lambda_function" "lambda_function" {
  filename      = var.filename
  function_name = var.function_name
  role          = var.lambda_exec_role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout

  source_code_hash = filebase64sha256(var.filename)

  environment {
    variables = var.environment_variables
  }

  layers = var.layers
}

output "lambda_function_arn" {
  value = aws_lambda_function.lambda_function.arn
}
