
#################################
## Create S3 Bucket for upload ##
#################################
resource "aws_s3_bucket" "tfbucket_in" {
  bucket        = var.tfbucket_in
  acl           = "private"
  force_destroy = true
  tags = {
    Name        = "My bucket for input"
    Project     = "Terraform"
    Environment = "Dev/Test"
  }
}

###################################
## Create S3 Bucket for download ##
###################################
resource "aws_s3_bucket" "tfbucket_out" {
  bucket        = var.tfbucket_out
  acl           = "private"
  force_destroy = true
  tags = {
    Name        = "My bucket for output"
    Project     = "Terraform"
    Environment = "Dev/Test"
  }
}

