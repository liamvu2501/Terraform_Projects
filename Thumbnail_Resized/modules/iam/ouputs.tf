output "mytf_instance_profile" {
  value       = aws_iam_instance_profile.mytf_instance_profile.arn
  description = "EC2 Instance profile"
}

output "mytf_lambda_role" {
  value       = aws_iam_role.mytf_lambda_role.arn
  description = "Lambda role"
}