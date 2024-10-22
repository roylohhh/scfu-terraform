# Output the Lambda invoke ARN
output "lambda_invoke_arn" {
  value = aws_lambda_function.lambda_function.invoke_arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.lambda_function.arn
}
