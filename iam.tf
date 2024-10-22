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
      # DynamoDB Permissions
      {
        Effect = "Allow",
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:Scan"
        ],
        Resource = aws_dynamodb_table.consent_form_table.arn
      },
      # S3 Permissions
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.csiro_consent_forms.arn}/*"
        ]
      },
      # CloudWatch Logs Permissions
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
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
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  description = "Allows Step Functions to access AWS resources on your behalf."
}

# IAM Policy for Step Functions Logging
resource "aws_iam_policy" "step_functions_logging_policy" {
  name        = "step_functions_logging_policy"
  description = "Policy for Step Functions Logging."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups",
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_step_functions_logging_policy" {
  role       = aws_iam_role.step_functions_exec_role.name
  policy_arn = aws_iam_policy.step_functions_logging_policy.arn
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
          module.lambda_validate_data.lambda_function_arn,
          module.lambda_put_s3.lambda_function_arn,
          module.lambda_dynamodb.lambda_function_arn
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
  description = "Allows API Gateway to access Step Function State Machines."
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
          aws_sfn_state_machine.sfn_state_machine.arn
        ]
      }
    ]
  })
}




# IAM Policy for API Gateway Logging
resource "aws_iam_policy" "api_gateway_logging_policy" {
  name        = "api_gateway_logging_policy"
  description = "Policy for API Gateway Logging."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach API Gateway Logging policy to API Gateway Step Functions role
resource "aws_iam_role_policy_attachment" "attach_api_gateway_logging_policy" {
  role       = aws_iam_role.api_gateway_to_step_functions_role.name
  policy_arn = aws_iam_policy.api_gateway_logging_policy.arn
}
