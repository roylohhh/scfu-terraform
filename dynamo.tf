#dynamodb

resource "aws_dynamodb_table" "consent_form_table" {
  name         = "consent_form_table"
  billing_mode = "PAY_PER_REQUEST"

  # Define the partition key (id) and sort key (version) for versioning
  hash_key     = "id"        # Partition Key
  range_key    = "version"   # Sort Key

  # Define the id as a string (S) and version as a number (N)
  attribute {
    name = "id"
    type = "S"   # String
  }

  attribute {
    name = "version"
    type = "N"   # Number
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }
}
