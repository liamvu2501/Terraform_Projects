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
