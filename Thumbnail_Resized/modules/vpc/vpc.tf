#Refer to: https://www.bogotobogo.com/DevOps/Terraform/Terraform-VPC-Subnet-ELB-RouteTable-SecurityGroup-Apache-Server-1.php

locals {
  vpc_tags = {
    Project     = "Terraform"
    Environment = "Dev/Test"
  }
}

#########################
## Create VPC elements ##
#########################
resource "aws_vpc" "myvpc" {
  cidr_block = var.myvpc_cidr
  tags       = local.vpc_tags
}

#Create Public Subnets with auto-assign pblic IPs
resource "aws_subnet" "public_subnets" {
  count                   = length(var.subnets_cidr)
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = element(var.subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags                    = local.vpc_tags
}

#Create Internet Gateway for the VPC
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
  tags   = local.vpc_tags
}

#When a VPC created, a defaut RT with local route only will also be created. So we just need to modify the default RT to have traffic to Internet thru IGW
resource "aws_default_route_table" "myrt" {
  default_route_table_id = aws_vpc.myvpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
  tags = local.vpc_tags
}

#Associate the default RT with all the public subnets
resource "aws_route_table_association" "myrtassoc" {
  count          = length(var.subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_default_route_table.myrt.id
}