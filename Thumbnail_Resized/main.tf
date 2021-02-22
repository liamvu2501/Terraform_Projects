module "vpc" {
  source       = "./modules/vpc"
  myvpc_cidr   = var.myvpc_cidr
  subnets_cidr = var.subnets_cidr
  azs          = var.azs
}

module "s3" {
  source       = "./modules/s3"
  tfbucket_in  = var.tfbucket_in
  tfbucket_out = var.tfbucket_out
}

module "iam" {
  source             = "./modules/iam"
  instance_role_name = var.instance_role_name
  lambda_role_name   = var.lambda_role_name
}

module "dynamodb" {
  source        = "./modules/dynamodb"
  dynamodb_name = var.dynamodb_name
}

module "frontend" {
  source                = "./modules/frontend"
  vpc_id                = module.vpc.myvpc_id
  subnet_ids            = module.vpc.mysubnet_ids
  myvpc_cidr            = var.myvpc_cidr
  azs                   = var.azs
  ami                   = var.ami
  instance_type         = var.instance_type
  min_cap               = var.min_cap
  max_cap               = var.max_cap
  mytf_instance_profile = module.iam.mytf_instance_profile
  key_pair              = var.key_pair
  region                = var.region
  tfbucket_in           = var.tfbucket_in
  tfbucket_out          = var.tfbucket_out
  dynamodb_name         = var.dynamodb_name
}

module "sns" {
  source     = "./modules/sns"
  topic_name = var.topic_name
}

module "lambda" {
  source        = "./modules/lambda"
  function_name = var.function_name
  lambda_role   = module.iam.mytf_lambda_role
  region        = var.region
  dynamodb_name = var.dynamodb_name
  topic_arn     = module.sns.topic_arn
}

output "elb_dns" {
  value = module.frontend.elb_dns
}
