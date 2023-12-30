# main.tf
provider "aws" {
  region = "us-east-1" # Replace with your preferred region
}
resource "aws_s3_bucket" "example_bucket" {
  bucket = "basapro-bucket-2024" # Replace with a globally unique bucket name
  acl    = "private" # Set bucket access control (e.g., private, public-read)
  # Enable versioning for the bucket
  versioning {
    enabled = true
  }
  # Define server-side encryption for the bucket using AWS-managed keys
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}