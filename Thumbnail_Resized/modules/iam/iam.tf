#############################
## Create Instance Profile ##
#############################

#Create a role and allow EC2 services to assume it
resource "aws_iam_role" "mytf_instance_role" {
  name = var.instance_role_name
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

#Create a policy with appropriate permision
resource "aws_iam_policy" "mytf_instance_policy" {
  name        = "mytf_instance_policy"
  description = "Policy for Instance role created with Terraform"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*",
        "ec2:*",
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

#Attach the role to the policy
resource "aws_iam_role_policy_attachment" "mytf_instance_role_attachment" {
  role       = aws_iam_role.mytf_instance_role.name
  policy_arn = aws_iam_policy.mytf_instance_policy.arn
}

#Create the instance profile
resource "aws_iam_instance_profile" "mytf_instance_profile" {
  name = "mytf_instance_profile"
  role = aws_iam_role.mytf_instance_role.name
}

#############################
#### Create Lambda role #####
#############################

#Create a role and assign to Lambda
resource "aws_iam_role" "mytf_lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

#Create a policy with appropriate permision
resource "aws_iam_policy" "mytf_lambda_policy" {
  name        = "mytf_lambda_policy"
  description = "Policy for Lambda role created with Terraform"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*",
        "dynamodb:*",
        "sns:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

#Attach the role to the policy
resource "aws_iam_role_policy_attachment" "mytf_lambda_role_attachment" {
  role       = aws_iam_role.mytf_lambda_role.name
  policy_arn = aws_iam_policy.mytf_lambda_policy.arn
}