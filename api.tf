# API Gateway
resource "aws_api_gateway_rest_api" "csiro_api" {
  name        = "CSIRO REST API Gateway"
  description = "API Gateway for serverless functions"
}

# API Gateway Resource for State Machine
resource "aws_api_gateway_resource" "execute_resource" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  parent_id   = aws_api_gateway_rest_api.csiro_api.root_resource_id
  path_part   = "execute"
}

# Cognito User Pool Authorizer
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name        = "cognito_authorizer"
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  type        = "COGNITO_USER_POOLS"
  provider_arns = [
    aws_cognito_user_pool.dcp-users.arn
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
    "method.response.header.Access-Control-Allow-Origin"      = "'http://10.0.0.16:3000'",
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }

  depends_on = [
    aws_api_gateway_integration.execute_options_integration
  ]
}

resource "aws_api_gateway_method" "execute_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.csiro_api.id
  resource_id   = aws_api_gateway_resource.execute_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}


resource "aws_api_gateway_integration_response" "execute_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  resource_id = aws_api_gateway_resource.execute_resource.id
  http_method = aws_api_gateway_method.execute_post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods"     = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"      = "'http://10.0.0.16:3000'", //CHANGEME
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }

  depends_on = [
    aws_api_gateway_integration.execute_post_integration
  ]
}



resource "aws_api_gateway_method_response" "execute_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  resource_id = aws_api_gateway_resource.execute_resource.id
  http_method = aws_api_gateway_method.execute_post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration" "execute_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.csiro_api.id
  resource_id             = aws_api_gateway_resource.execute_resource.id
  http_method             = aws_api_gateway_method.execute_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:ap-southeast-2:states:action/StartSyncExecution"

  credentials = aws_iam_role.api_gateway_to_step_functions_role.arn
  request_templates = {
    "application/json" = <<EOF
    #set($data = $util.escapeJavaScript($input.json('$.input')))
    {
        "input": "$data",
    "stateMachineArn": $input.json('$.statemachinearn')
    }
EOF
  }
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "csiro_api_gateway_deployment" {
  depends_on = [
    aws_api_gateway_integration.execute_post_integration,
    aws_api_gateway_integration.execute_options_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  # stage_name  = "prod"
}

# Create the API Gateway Stage
resource "aws_api_gateway_stage" "csiro_api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.csiro_api.id
  stage_name    = "prod"
  deployment_id = aws_api_gateway_deployment.csiro_api_gateway_deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.csiro_api_gateway_log_group.arn
    format          = "$context.requestId $context.identity.sourceIp $context.requestTime $context.httpMethod $context.resourcePath $context.status $context.responseLength"
  }
}


# API Gateway Stage with logging enabled
resource "aws_api_gateway_method_settings" "csiro_api_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.csiro_api.id
  stage_name  = aws_api_gateway_stage.csiro_api_stage.stage_name # Reference the stage here
  method_path = "*/*"                                            # Log all methods
  settings {
    logging_level      = "INFO" # Options: OFF, ERROR, INFO, or DEBUG
    data_trace_enabled = true
    metrics_enabled    = true
  }
}
