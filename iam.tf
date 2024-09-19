# iam.tf

# IAM Role for Lambda Execution 
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

# IAM Policy for DynamoDB and S3 Access
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:Scan",
          "s3:PutObject",
          "s3:GetObject",
          "logs:CreateLogGroup",         
          "logs:CreateLogStream",        
          "logs:PutLogEvents"           
        ],
        Resource = [
          aws_dynamodb_table.consent_form_table.arn,
          "${aws_s3_bucket.lambda_layer_bucket.arn}/*",
           "arn:aws:logs:*:*:*" 
        ]
      }
    ]
  })
}
