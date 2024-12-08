# outputs.tf

output "csiro_consent_bucket_name" {
  value       = aws_s3_bucket.csiro_consent_forms.bucket
  description = "Name of CSIRO Consent Forms S3 bucket"
}

output "csiro_api_id" {
  value = aws_api_gateway_rest_api.csiro_api.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.dcp-users.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.dcp-users-client.id
}

output "state_machine_id" {
  value = aws_sfn_state_machine.sfn_state_machine.arn
}
