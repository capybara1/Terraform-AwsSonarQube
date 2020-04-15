provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}


locals {
  server_subnet_index = 0
}


module "vpc" {
  source = "github.com/capybara1/Terraform-AwsBasicVpc?ref=v2.0.0"

  vpc_cidr_block            = var.vpc_cidr_block
  prefix                    = var.prefix
  number_of_private_subnets = 0
}

module "service" {
  source = "./modules/service"

  prefix          = var.prefix
  vpc_id          = module.vpc.vpc_id
  vpc_cidr_block  = var.vpc_cidr_block
  subnet          = module.vpc.public_subnets[local.server_subnet_index]
  service_domain  = var.service_domain
  ssh_whitelist   = var.ssh_whitelist
  public_key_path = var.public_key_path
  instance_type   = var.instance_type
}

module "lb" {
  source = "./modules/lb"

  prefix         = var.prefix
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnets[*].id
  instance_id    = module.service.instance_id
  service_domain = var.service_domain
  cert_domain    = var.cert_domain
  zone           = var.zone
}
