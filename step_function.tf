resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "csiro_state_machine"
  role_arn = aws_iam_role.step_functions_exec_role.arn
  type     = "EXPRESS"

  definition = jsonencode(

    {
      "StartAt" : "Validate Data",
      "States" : {
        "Check Upload Status" : {
          "Choices" : [
            {
              "Next" : "Write to DynamoDB",
              "StringEquals" : "success",
              "Variable" : "$.formUploadlambdaOutput.status"
            }
          ],
          "Default" : "Handle UploadPDF Error",
          "Type" : "Choice"
        },
        "Check Write Status" : {
          "Choices" : [
            {
              "Next" : "Handle Success",
              "StringEquals" : "success",
              "Variable" : "$.dynamoDbOutput.status"
            }
          ],
          "Default" : "Handle DynamoDB Error",
          "Type" : "Choice"
        },
        "Handle DynamoDB Error" : {
          "InputPath" : "$.dynamoDbOutput",
          "Parameters" : {
            "message.$" : "$.message",
            "status.$" : "$.status",
            "statusCode" : 400
          },
          "Type" : "Pass",
          "End" : true
        },
        "Handle UploadPDF Error" : {
          "InputPath" : "$.formUploadlambdaOutput",
          "Parameters" : {
            "message.$" : "$.message",
            "status.$" : "$.status",
            "statusCode" : 400
          },
          "Type" : "Pass",
          "End" : true
        },
        "Handle ValidateData Error" : {
          "End" : true,
          "InputPath" : "$.validateLambdaOutput",
          "Parameters" : {
            "errors.$" : "$.errors",
            "status.$" : "$.status",
            "statusCode" : 400
          },
          "Type" : "Pass"
        },
        "Handle Success" : {
          "End" : true,
          "Type" : "Pass",
          "Parameters" : {
            "message.$" : "$.message",
            "status.$" : "$.status",
            "statusCode" : 200
          },
          "InputPath" : "$.dynamoDbOutput"
        },
        "Is Data Valid" : {
          "Choices" : [
            {
              "Next" : "Upload PDF",
              "StringEquals" : "success",
              "Variable" : "$.validateLambdaOutput.status"
            }
          ],
          "Default" : "Handle ValidateData Error",
          "Type" : "Choice"
        },
        "Step Functions Error" : {
          "CausePath" : "$.Cause",
          "ErrorPath" : "$.Error",
          "Type" : "Fail"
        },
        "Upload PDF" : {
          "Catch" : [
            {
              "ErrorEquals" : [
                "States.ALL"
              ],
              "Next" : "Step Functions Error"
            }
          ],
          "InputPath" : "$",
          "Next" : "Check Upload Status",
          "Parameters" : {
            "admin.$" : "$.admin",
            "formData.$" : "$.formData",
            "scannedForm.$" : "$.scannedForm",
            "timeStamp.$" : "$.validateLambdaOutput.timeStamp"
          },
          "Resource" : module.lambda_put_s3.lambda_function_arn,
          "ResultPath" : "$.formUploadlambdaOutput",
          "Retry" : [
            {
              "BackoffRate" : 2,
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 1,
              "MaxAttempts" : 3
            }
          ],
          "Type" : "Task"
        },
        "Validate Data" : {
          "Next" : "Is Data Valid",
          "Parameters" : {
            "admin.$" : "$.admin",
            "formData.$" : "$.formData",
            "scannedForm.$" : "$.scannedForm"
          },
          "Resource" : module.lambda_validate_data.lambda_function_arn,
          "ResultPath" : "$.validateLambdaOutput",
          "Retry" : [
            {
              "BackoffRate" : 2,
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 1,
              "MaxAttempts" : 3
            }
          ],
          "Type" : "Task",
          "Catch" : [
            {
              "ErrorEquals" : [
                "States.ALL"
              ],
              "Next" : "Step Functions Error"
            }
          ]
        },
        "Write to DynamoDB" : {
          "Next" : "Check Write Status",
          "Parameters" : {
            "admin.$" : "$.admin",
            "formData.$" : "$.formData",
            "s3Map.$" : "$.formUploadlambdaOutput.s3Map",
            "timeStamp.$" : "$.validateLambdaOutput.timeStamp",

          },
          "Resource" : module.lambda_dynamodb.lambda_function_arn,
          "ResultPath" : "$.dynamoDbOutput",
          "Retry" : [
            {
              "BackoffRate" : 2,
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 1,
              "MaxAttempts" : 3
            }
          ],
          "Type" : "Task",
          "Catch" : [
            {
              "ErrorEquals" : [
                "States.ALL"
              ],
              "Next" : "Step Functions Error"
            }
          ]
        }
      }
    }
  )
  depends_on = [
    module.lambda_validate_data,
    module.lambda_put_s3,
    module.lambda_dynamodb
  ]

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.csiro_state_machine_log_group.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}
