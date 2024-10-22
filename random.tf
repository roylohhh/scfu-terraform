# random.tf

# Generate a random string for unique suffix
resource "random_string" "unique_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Generate a random ID for bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
