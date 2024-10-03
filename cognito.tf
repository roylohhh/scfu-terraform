# cognito.tf

resource "aws_cognito_user_pool" "user_pool" {
  name = "cognito-apigateway"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "cognito-apigateway"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

# https://medium.com/carlos-hernandez/user-control-with-cognito-and-api-gateway-4c3d99b2f414
# Temporary: I'll move this comment somewhere else, maybe in confluence - Roy
