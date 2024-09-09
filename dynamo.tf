#dynamodb

resource "aws_dynamodb_table" "consent_form_table" {
  name         = "consent_form_table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

