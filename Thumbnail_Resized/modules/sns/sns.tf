###########################
#### Create SNS topic #####
###########################

#As AWS SNS policy has changed, you need to register a toll-free or 10DLC number to be able to send SMS. 
#Terraform also does not support email as an endpoint, as it cannot provide auto-subscription. 
#But there are few ways to auto-subscribe email, as discussed below:
#https://medium.com/@raghuram.arumalla153/aws-sns-topic-subscription-with-email-protocol-using-terraform-ed05f4f19b73

resource "aws_sns_topic" "tftopic" {
  name = var.topic_name

  #We will make use of local-exec provisioner to execute aws cli locally to subscribe to the SNS topic
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.email}"
  }
}