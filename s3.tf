# s3.tf

# Define S# bucket to store pdf
resource "aws_s3_bucket" "csiro_consent_forms" {
  bucket = "csiro-consent-forms-${random_string.unique_suffix.result}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "CsiroConsentFormsBucket"
    Environment = "Development"
  }
}

# Define S3 bucket to store Lambda layer zip
resource "aws_s3_bucket" "lambda_layer_bucket" {
  bucket = "lambda-layer-bucket-${random_string.unique_suffix.result}-${random_id.bucket_suffix.hex}" # Unique name using random values

  tags = {
    Name        = "LambdaLayerBucket"
    Environment = "Development"
  }
}

