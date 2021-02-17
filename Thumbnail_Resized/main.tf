module "vpc" {
  source       = "./modules/vpc"
  myvpc_cidr   = var.myvpc_cidr
  subnets_cidr = var.subnets_cidr
  azs          = var.azs
}
