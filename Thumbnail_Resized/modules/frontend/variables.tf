variable "ingress" {
  description = "Allowed ingress traffic"
  type        = list(number)
  default     = [80, 443, 3300]
}

variable "egress" {
  description = "Allowed traffic to VPC only"
  type        = list(number)
  default     = [80, 443]
}

variable "myvpc_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
}
variable "ami" {
  type = string
}

variable "azs" {
  type = list(any)
}

variable "min_cap" {
  type = number
}

variable "max_cap" {
  type = number
}

variable "mytf_instance_profile" {
  type = string
}

variable "key_pair" {
  type = string
}

variable "region" {
  type = string
}

variable "tfbucket_in" {
  type = string
}
variable "tfbucket_out" {
  type = string
}

variable "dynamodb_name" {
  type = string
}