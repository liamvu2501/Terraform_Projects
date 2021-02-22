resource "aws_dynamodb_table" "tfdynamodb" {
  name           = var.dynamodb_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "Email"
  range_key      = "UUID"

  attribute {
    name = "Email"
    type = "S"
  }
  
  attribute {
    name = "UUID"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name        = "My TF DynamoDB Table"
    Project     = "Terraform"
    Environment = "Dev/Test"
  }
}