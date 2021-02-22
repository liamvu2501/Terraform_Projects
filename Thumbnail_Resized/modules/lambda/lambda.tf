resource "aws_lambda_function" "tflambda" {
  filename      = "editor.zip"
  function_name = var.function_name
  role          = var.lambda_role
  handler       = "editor.handler"

  source_code_hash = filebase64sha256("editor.zip")

  runtime = "python3.6"

  environment {
    variables = {
      region = var.region
      table_name = var.dynamodb_name
      topic_arn  = var.topic_arn
    }
  }
}