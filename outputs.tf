# outputs.tf

output "lambda_layer_bucket_name" {
  value       = aws_s3_bucket.lambda_layer_bucket.bucket
  description = "The name of the S3 bucket storing the Lambda layer"
}

output "unique_suffix" {
  value       = random_string.unique_suffix.result
  description = "Unique suffix generated for resource naming"
}

output "bucket_suffix" {
  value       = random_id.bucket_suffix.hex
  description = "Random ID generated for bucket naming"
}
