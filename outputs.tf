# outputs.tf

output "unique_suffix" {
  value       = random_string.unique_suffix.result
  description = "Unique suffix generated for resource naming"
}

output "bucket_suffix" {
  value       = random_id.bucket_suffix.hex
  description = "Random ID generated for bucket naming"
}

output "csiro_api_id" {
  value = aws_api_gateway_rest_api.csiro_api.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}
