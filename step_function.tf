resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "csiro_state_machine"
  role_arn = aws_iam_role.step_functions_exec_role.arn
  type     = "EXPRESS" # comment this out for standard
  definition = jsonencode(

    {
      "StartAt" : "Validate Data",
      "States" : {
        "Validate Data" : {
          "Type" : "Task",
          "Resource" : module.lambda_validate_data.lambda_function_arn, // TODO:Update how lambda ARN is being imported
          "Parameters" : {
            "formData.$" : "$.formData",
            "scannedForm.$" : "$.scannedForm",
            "admin.$" : "$.admin"
          },
          "Retry" : [
            {
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 1,
              "MaxAttempts" : 3,
              "BackoffRate" : 2
            }
          ],
          "Next" : "Is Data Valid",
          "ResultPath" : "$.validateLambdaOutput"
        },
        "Is Data Valid" : {
          "Type" : "Choice",
          "Choices" : [
            {
              "Variable" : "$.validateLambdaOutput.status",
              "StringEquals" : "success",
              "Next" : "Upload PDF"
            }
          ],
          "Default" : "Handle Errors"
        },
        "Upload PDF" : {
          "Type" : "Task",
          "Resource" : module.lambda_put_s3.lambda_function_arn, //TODO: Update how lambda ARN is being imported
          "Parameters" : {
            "formData.$" : "$.formData",
            "scannedForm.$" : "$.scannedForm",
            "admin.$" : "$.admin",
            "timeStamp.$" : "$.validateLambdaOutput.timeStamp"
          },
          "Retry" : [
            {
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 1,
              "MaxAttempts" : 3,
              "BackoffRate" : 2
            }
          ],
          "Next" : "Check Upload Status",
          "Catch" : [
            {
              "ErrorEquals" : [
                "States.ALL"
              ],
              "Next" : "Step Functions Error"
            }
          ],
          "ResultPath" : "$.formUploadlambdaOutput",
          "InputPath" : "$"
        },
        "Check Upload Status" : {
          "Type" : "Choice",
          "Choices" : [
            {
              "Variable" : "$.formUploadlambdaOutput.status",
              "StringEquals" : "success",
              "Next" : "Write to DynamoDB"
            }
          ],
          "Default" : "Handle Errors"
        },
        "Step Functions Error" : {
          "Type" : "Fail",
          "ErrorPath" : "$.Error",
          "CausePath" : "$.Cause"
        },
        "Write to DynamoDB" : {
          "Type" : "Task",
          "Resource" : module.lambda_dynamodb.lambda_function_arn, //TODO: Update how lambda ARN is being imported
          "Parameters" : {
            "formData.$" : "$.formData",
            "admin.$" : "$.admin",
            "originalS3ObjectKey.$" : "$.formUploadlambdaOutput.originalS3ObjectKey",
            "originalS3Hash.$" : "$.formUploadlambdaOutput.originalS3Hash",
            "watermarkedS3ObjectKey.$" : "$.formUploadlambdaOutput.watermarkedS3ObjectKey",
            "watermarkedS3Hash.$" : "$.formUploadlambdaOutput.watermarkedS3Hash",
            "timeStamp.$" : "$.validateLambdaOutput.timeStamp"
          },
          "Retry" : [
            {
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 1,
              "MaxAttempts" : 3,
              "BackoffRate" : 2
            }
          ],
          "Next" : "Check Write Status",
          "ResultPath" : "$.dynamoDbOutput"
        },
        "Check Write Status" : {
          "Type" : "Choice",
          "Choices" : [
            {
              "Variable" : "$.dynamoDbOutput.status",
              "StringEquals" : "success",
              "Next" : "Handle Success"
            }
          ],
          "Default" : "Handle Errors"
        },
        "Handle Success" : {
          "Type" : "Pass",
          "End" : true
        },
        "Handle Errors" : {
          "Type" : "Pass",
          "End" : true,
          "Parameters" : {
            "statusCode" : 400,
            "status.$" : "$.status",
            "errors.$" : "$.errors"
          },
          "InputPath" : "$"
        }
      }
    }
  )
  depends_on = [
    module.lambda_validate_data,
    module.lambda_put_s3,
    module.lambda_dynamodb
  ]
}



