resource "aws_sns_topic" "tftopic" {
  name = var.topic_name
}