variable "filename" {
  description = "Path to the Lambda zip file"
}

variable "function_name" {
  description = "Name of the Lambda function"
}

variable "lambda_exec_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
}

variable "handler" {
  description = "Lambda function handler (e.g., 'index.handler')"
}

variable "runtime" {
  description = "Lambda function runtime (e.g., 'nodejs14.x')"
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
}

variable "layers" {
  description = "Lambda function layers"
  type        = list(string)
  default     = []
}
