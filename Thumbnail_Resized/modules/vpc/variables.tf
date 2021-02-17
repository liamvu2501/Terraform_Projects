variable "myvpc_cidr" {
  type    = string
  default = "10.53.0.0/16"
}

variable "subnets_cidr" {
  type    = list(any)
  default = ["10.53.1.0/24", "10.53.2.0/24", "10.53.3.0/24"]
}

variable "azs" {
  type    = list(any)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}
