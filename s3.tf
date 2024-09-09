# s3.tf

# Define S3 bucket to store Lambda layer zip
resource "aws_s3_bucket" "lambda_layer_bucket" {
  bucket = "lambda-layer-bucket-${random_string.unique_suffix.result}-${random_id.bucket_suffix.hex}" # Unique name using random values

  tags = {
    Name        = "LambdaLayerBucket"
    Environment = "Development"
  }
}

