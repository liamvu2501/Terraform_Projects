variable "region" {
  type = string
}

#####################
### VPC variables ###
#####################

variable "myvpc_cidr" {
  type = string
}

variable "subnets_cidr" {
  type = list(any)
}

variable "azs" {
  type = list(any)
}


##########################
### Frontend variables ###
##########################

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "min_cap" {
  type = number
}

variable "max_cap" {
  type = number
}

variable "key_pair" {
  type = string
}


####################
### S3 variables ###
####################

variable "tfbucket_in" {
  type = string
}
variable "tfbucket_out" {
  type = string
}


#####################
### IAM variables ###
#####################
variable "instance_role_name" {
  type = string
}

variable "lambda_role_name" {
  type = string
}

##########################
### DynampDB variables ###
##########################
variable "dynamodb_name" {
  type = string
}

#####################
### SNS variables ###
#####################
variable "topic_name" {
  type = string
}

########################
### Lambda variables ###
########################
variable "function_name" {
  type = string
}