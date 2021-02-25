#################################
#### Create Lambda function #####
#################################

#Upload zip file from local
resource "aws_lambda_function" "tflambda" {
  filename      = "${path.module}/editor.zip"
  function_name = var.function_name
  role          = var.lambda_role
  handler       = "editor.handler"

  #When updating the package, the hash will change and TF will update the function without the need to delete & re-create the function
  source_code_hash = filebase64sha256("${path.module}/editor.zip")

  runtime = "python3.6"

  timeout = 30

  #Environment variables will be passed to the editor.py. The values are from user's input
  environment {
    variables = {
      region     = var.region
      table_name = var.dynamodb_name
      topic_arn  = var.topic_arn
    }
  }
}

#############################################
#### Create Lambda event source mapping #####
#############################################

#DynamoDB stream as an event source
resource "aws_lambda_event_source_mapping" "event_mapping" {
  event_source_arn  = var.stream_arn
  function_name     = aws_lambda_function.tflambda.arn
  starting_position = "LATEST"
}