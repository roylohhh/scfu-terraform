# layer.tf

# Upload the Lambda layer zip to S3
resource "aws_s3_object" "lambda_layer_object" {
  bucket = aws_s3_bucket.lambda_layer_bucket.bucket
  key    = "nodejs.zip"
  source = "${path.module}/lambda-layer/nodejs.zip" # Local path to your layer zip file
}

# Create the Lambda layer
resource "aws_lambda_layer_version" "my_layer" {
  layer_name          = "my-layer"
  s3_bucket           = aws_s3_bucket.lambda_layer_bucket.bucket
  s3_key              = aws_s3_object.lambda_layer_object.key
  compatible_runtimes = ["nodejs20.x"]
  description         = "Layer containing Node.js libraries for Lambda functions"
}