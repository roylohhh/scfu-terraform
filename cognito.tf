# Cognito User Pool
resource "aws_cognito_user_pool" "dcp-users" {
  name = "dcp-users"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  schema {
    name                     = "terraform"
    attribute_data_type      = "Boolean"
    developer_only_attribute = false
    mutable                  = false
    required                 = false
  }

  password_policy {
    temporary_password_validity_days = 7
    minimum_length                   = 6
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
  }
}

# Pool Client
resource "aws_cognito_user_pool_client" "dcp-users-client" {
  name         = "dcp-users-client"
  user_pool_id = aws_cognito_user_pool.dcp-users.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

# admin user
resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.dcp-users.id
  username     = "admin@test.com"
  password     = "Admin1234!"

  attributes = {
    terraform      = true
    given_name     = "Admin"
    family_name    = "Admin"
    email          = "admin@test.com"
    email_verified = true
  }
}
# https://medium.com/carlos-hernandez/user-control-with-cognito-and-api-gateway-4c3d99b2f414
