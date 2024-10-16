# Combined API Gateway for S3 and DynamoDB
resource "aws_api_gateway_rest_api" "csiro_api" {
  name        = "CSIRO REST API Gateway"
  description = "API Gateway for serverless functions"
}

# # API Gateway Resource for S3
# resource "aws_api_gateway_resource" "s3_put_object_resource" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   parent_id   = aws_api_gateway_rest_api.csiro_api.root_resource_id
#   path_part   = "put-object"
# }

# # API Gateway Resource for DynamoDB
# resource "aws_api_gateway_resource" "put_item_resource" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   parent_id   = aws_api_gateway_rest_api.csiro_api.root_resource_id
#   path_part   = "put-item"
# }

# API Gateway Resource for State Machine
resource "aws_api_gateway_resource" "execute_resource" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  parent_id   = aws_api_gateway_rest_api.csiro_api.root_resource_id
  path_part   = "execute"
}

# Cognito User Pool Authorizer
resource "aws_api_gateway_authorizer" "combined_authorizer" {
  name        = "combined_authorizer"
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  type        = "COGNITO_USER_POOLS"
  provider_arns = [
    aws_cognito_user_pool.user_pool.arn
  ]
}

# CORS setup for State Machine Execute Route
resource "aws_api_gateway_method" "execute_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.csiro_api.id
  resource_id   = aws_api_gateway_resource.execute_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "execute_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  resource_id = aws_api_gateway_resource.execute_resource.id
  http_method = aws_api_gateway_method.execute_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration" "execute_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  resource_id = aws_api_gateway_resource.execute_resource.id
  http_method = aws_api_gateway_method.execute_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "execute_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  resource_id = aws_api_gateway_resource.execute_resource.id
  http_method = aws_api_gateway_method.execute_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods"     = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"      = "'http://scfu-frontend.s3-website-ap-southeast-2.amazonaws.com'",
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }

  depends_on = [
    aws_api_gateway_integration.execute_options_integration
  ]
}

resource "aws_api_gateway_method" "execute_method" {
  rest_api_id   = aws_api_gateway_rest_api.csiro_api.id
  resource_id   = aws_api_gateway_resource.execute_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.combined_authorizer.id
}

resource "aws_api_gateway_method_response" "execute_method_response" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  resource_id = aws_api_gateway_resource.execute_resource.id
  http_method = aws_api_gateway_method.execute_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration" "execute_integration" {
  rest_api_id             = aws_api_gateway_rest_api.csiro_api.id
  resource_id             = aws_api_gateway_resource.execute_resource.id
  http_method             = aws_api_gateway_method.execute_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:ap-southeast-2:states:action/StartSyncExecution"

  credentials = aws_iam_role.step_functions_exec_role.id
}


# # CORS setup for S3 put-object
# resource "aws_api_gateway_method" "s3_options_method" {
#   rest_api_id   = aws_api_gateway_rest_api.csiro_api.id
#   resource_id   = aws_api_gateway_resource.s3_put_object_resource.id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_method_response" "s3_options_method_response" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   resource_id = aws_api_gateway_resource.s3_put_object_resource.id
#   http_method = aws_api_gateway_method.s3_options_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers"     = true,
#     "method.response.header.Access-Control-Allow-Methods"     = true,
#     "method.response.header.Access-Control-Allow-Origin"      = true,
#     "method.response.header.Access-Control-Allow-Credentials" = true
#   }
# }

# resource "aws_api_gateway_integration" "s3_options_integration" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   resource_id = aws_api_gateway_resource.s3_put_object_resource.id
#   http_method = aws_api_gateway_method.s3_options_method.http_method
#   type        = "MOCK"

#   request_templates = {
#     "application/json" = "{\"statusCode\": 200}"
#   }
# }

# resource "aws_api_gateway_integration_response" "s3_options_integration_response" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   resource_id = aws_api_gateway_resource.s3_put_object_resource.id
#   http_method = aws_api_gateway_method.s3_options_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
#     "method.response.header.Access-Control-Allow-Methods"     = "'GET,OPTIONS,POST,PUT'",
#     "method.response.header.Access-Control-Allow-Origin"      = "'http://scfu-frontend.s3-website-ap-southeast-2.amazonaws.com'",
#     "method.response.header.Access-Control-Allow-Credentials" = "'true'"
#   }

#   depends_on = [
#     aws_api_gateway_integration.s3_options_integration
#   ]
# }

# resource "aws_api_gateway_method" "s3_put_object_method" {
#   rest_api_id   = aws_api_gateway_rest_api.csiro_api.id
#   resource_id   = aws_api_gateway_resource.s3_put_object_resource.id
#   http_method   = "POST"
#   authorization = "COGNITO_USER_POOLS"
#   authorizer_id = aws_api_gateway_authorizer.combined_authorizer.id
# }

# resource "aws_api_gateway_method_response" "s3_put_object_method_response" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   resource_id = aws_api_gateway_resource.s3_put_object_resource.id
#   http_method = aws_api_gateway_method.s3_put_object_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin"      = true,
#     "method.response.header.Access-Control-Allow-Methods"     = true,
#     "method.response.header.Access-Control-Allow-Headers"     = true,
#     "method.response.header.Access-Control-Allow-Credentials" = true
#   }
# }

# resource "aws_api_gateway_integration" "s3_lambda_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.csiro_api.id
#   resource_id             = aws_api_gateway_resource.s3_put_object_resource.id
#   http_method             = aws_api_gateway_method.s3_put_object_method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = module.lambda_put_s3.lambda_invoke_arn
# }

# resource "aws_lambda_permission" "s3_apigw_lambda_permission" {
#   statement_id  = "AllowAPIGatewayInvokeS3"
#   action        = "lambda:InvokeFunction"
#   function_name = module.lambda_put_s3.lambda_function_arn
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.csiro_api.execution_arn}/*/*"
# }



# # CORS setup for DynamoDB put-item
# resource "aws_api_gateway_method" "dynamodb_options_method" {
#   rest_api_id   = aws_api_gateway_rest_api.csiro_api.id
#   resource_id   = aws_api_gateway_resource.put_item_resource.id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_method_response" "dynamodb_options_method_response" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   resource_id = aws_api_gateway_resource.put_item_resource.id
#   http_method = aws_api_gateway_method.dynamodb_options_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers"     = true,
#     "method.response.header.Access-Control-Allow-Methods"     = true,
#     "method.response.header.Access-Control-Allow-Origin"      = true,
#     "method.response.header.Access-Control-Allow-Credentials" = true
#   }
# }

# resource "aws_api_gateway_integration" "dynamodb_options_integration" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   resource_id = aws_api_gateway_resource.put_item_resource.id
#   http_method = aws_api_gateway_method.dynamodb_options_method.http_method
#   type        = "MOCK"

#   request_templates = {
#     "application/json" = "{\"statusCode\": 200}"
#   }
# }

# resource "aws_api_gateway_integration_response" "dynamodb_options_integration_response" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   resource_id = aws_api_gateway_resource.put_item_resource.id
#   http_method = aws_api_gateway_method.dynamodb_options_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
#     "method.response.header.Access-Control-Allow-Methods"     = "'GET,OPTIONS,POST,PUT'",
#     "method.response.header.Access-Control-Allow-Origin"      = "'http://scfu-frontend.s3-website-ap-southeast-2.amazonaws.com'",
#     "method.response.header.Access-Control-Allow-Credentials" = "'true'"
#   }

#   depends_on = [
#     aws_api_gateway_integration.dynamodb_options_integration
#   ]
# }



# resource "aws_api_gateway_method" "put_item_method" {
#   rest_api_id   = aws_api_gateway_rest_api.csiro_api.id
#   resource_id   = aws_api_gateway_resource.put_item_resource.id
#   http_method   = "POST"
#   authorization = "COGNITO_USER_POOLS"
#   authorizer_id = aws_api_gateway_authorizer.combined_authorizer.id
# }

# resource "aws_api_gateway_method_response" "put_item_method_response" {
#   rest_api_id = aws_api_gateway_rest_api.csiro_api.id
#   resource_id = aws_api_gateway_resource.put_item_resource.id
#   http_method = aws_api_gateway_method.put_item_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers"     = true,
#     "method.response.header.Access-Control-Allow-Methods"     = true,
#     "method.response.header.Access-Control-Allow-Origin"      = true,
#     "method.response.header.Access-Control-Allow-Credentials" = true
#   }
# }

# resource "aws_api_gateway_integration" "dynamodb_lambda_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.csiro_api.id
#   resource_id             = aws_api_gateway_resource.put_item_resource.id
#   http_method             = aws_api_gateway_method.put_item_method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = module.lambda_dynamodb.lambda_invoke_arn
# }

# resource "aws_lambda_permission" "dynamodb_apigw_lambda_permission" {
#   statement_id  = "AllowAPIGatewayInvokeDynamoDB"
#   action        = "lambda:InvokeFunction"
#   function_name = module.lambda_dynamodb.lambda_function_arn
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.csiro_api.execution_arn}/*/*"
# }

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "csiro_api_gateway_deployment" {
  depends_on = [
    aws_api_gateway_integration.execute_integration,
    aws_api_gateway_integration.execute_options_integration
    # aws_api_gateway_integration.s3_lambda_integration,
    # aws_api_gateway_integration.dynamodb_lambda_integration,
    # aws_api_gateway_integration.s3_options_integration,
    # aws_api_gateway_integration.dynamodb_options_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  stage_name  = "prod"
}
