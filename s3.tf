# s3.tf

# Define S# bucket to store pdf
resource "aws_s3_bucket" "csiro_consent_forms" {
  bucket = "csiro-consent-forms-${random_string.unique_suffix.result}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "CsiroConsentFormsBucket"
    Environment = "Development"
  }
}

resource "aws_s3_bucket_versioning" "versioning_csiro_consent_forms" {
  bucket = aws_s3_bucket.csiro_consent_forms.id
  versioning_configuration {
    status = "Enabled"
  }
}
