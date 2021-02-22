locals {
  alb_tags = {
    Project     = "Terraform"
    Environment = "Dev/Test"
    Type        = "App_LB"
  }
}

#######################
## Create SG for ELB ##
#######################

#Create Load Balancer's Security Group
resource "aws_security_group" "elb_sg" {

  name        = "TF-SG-ELB"
  description = "Security group for ELB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ELB egress block to send traffic to VPC only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.myvpc_cidr] #["10.53.0.0/16"]
  }
  tags = local.alb_tags
}

################
## Create ELB ##
################

#Create ALB
resource "aws_alb" "myalb" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = var.subnet_ids
  tags               = local.alb_tags
}

#Create ALB's Target Group
resource "aws_alb_target_group" "mytg" {
  name     = "myTargetGroup"
  port     = 3300
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
    port = 80
  }
  tags = local.alb_tags
}

#Create ALB's Listener that listen on port 80 and forward to Target Group port 3300
resource "aws_alb_listener" "mylistener" {
  load_balancer_arn = aws_alb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.mytg.arn
  }
}

#Create a listener's rule to forward all traffic
resource "aws_alb_listener_rule" "standard" {
  listener_arn = aws_alb_listener.mylistener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.mytg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}