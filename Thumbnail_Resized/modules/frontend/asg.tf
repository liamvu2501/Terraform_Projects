locals {
  asg_tags = {
    Project     = "Terraform"
    Environment = "Dev/Test"
    Type        = "AutoScailing_Group"
  }
}

#######################
## Create SG for ASG ##
#######################

#Create ASG's Security Group
resource "aws_security_group" "asg_sg" {

  name        = "TF-SG-ASG"
  description = "Security group for ASG"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Dynamic ingress block for ingress traffic
  dynamic "ingress" {
    for_each = var.ingress
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.myvpc_cidr] #["10.53.0.0/16"]
    }
  }
  tags = local.asg_tags
}

################
## Create ASG ##
################

#Create Launch Template - all the instances need to have either public IP addresses or NAT (if placed in private subnets) to be able to execute user_data's script
resource "aws_launch_template" "mytemplate" {
  name          = "mytemplate"
  image_id      = var.ami
  instance_type = var.instance_type
  iam_instance_profile {
    arn = var.mytf_instance_profile
  }
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.asg_sg.id]
  #We will templatefile function to pass arguments into our shell script. Refer to https://stackoverflow.com/questions/62598410/how-to-pass-the-templatefile-function-to-user-data-argument-of-ec2-resource-in-t
  #Base64 encoding is needed for user_data. The templatefile function will not do it so you will need to wrap it inside base64encode funtion
  user_data = base64encode(templatefile("${path.module}/myscript.sh", {
    region        = var.region
    tfbucket_in   = var.tfbucket_in
    tfbucket_out  = var.tfbucket_out
    dynamodb_name = var.dynamodb_name
  }))
  tags = local.asg_tags
}

#Create Autoscailing Group
resource "aws_autoscaling_group" "myasg" {
  #desired_capacity    = var.desired_cap
  max_size            = var.max_cap
  min_size            = var.min_cap
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.mytemplate.id
    version = "$Latest"
  }
  tag {
    key                 = "Project"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Dev/Test"
    propagate_at_launch = true
  }

  tag {
    key                 = "Type"
    value               = "AutoScailing_Group"
    propagate_at_launch = true
  }

}

#Either choose this - Dynamic scailing base on avg CPU ultilization or use Simple Step scailing with desired_capacity
resource "aws_autoscaling_policy" "myasgpolicy" {
  name                   = "myasgpolicy"
  autoscaling_group_name = aws_autoscaling_group.myasg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 80.0
  }
}

#Attach the ASG to the ALB
resource "aws_autoscaling_attachment" "myasg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.myasg.id
  alb_target_group_arn   = aws_alb_target_group.mytg.arn
}