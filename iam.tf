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
          "arn:aws:logs:*:*:*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.csiro_consent_forms.arn}/*",
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
}


# IAM Role for Step Functions to Execute Lambda Functions
resource "aws_iam_role" "step_functions_exec_role" {
  name = "step_functions_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  description = "Allows Step Functions to access AWS resources on your behalf."
}

# IAM Role Policy for Step Functions to Access/Invoke Lambda Functions
resource "aws_iam_role_policy" "step_functions_lambda_policy" {
  name = "step_functions_lambda_policy"
  role = aws_iam_role.step_functions_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          aws_lambda_function.validate_data.arn,
          aws_lambda_function.upload_pdf.arn,
          aws_lambda_function.database_write.arn

          // TODO:Update how lambda ARN is being imported
        ]
      }
    ]
  })
}

# IAM Role for API Gateway to Invoke Step Functions
resource "aws_iam_role" "api_gateway_to_step_functions_role" {
  name = "api_gateway_to_step_functions_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  description = "Allows Step Functions to access AWS resources on your behalf."
}

# IAM Role Policy for API Gateway to Access State Machine
resource "aws_iam_role_policy" "api_gateway_step_functions_policy" {
  name = "api_gateway_step_functions_policy"

  role = aws_iam_role.api_gateway_to_step_functions_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["states:StartSyncExecution"]
        Resource = [
          aws_sfn_state_machine.csiro_state_machine.arn
        ]
      }
    ]
  })
}
