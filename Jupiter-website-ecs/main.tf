# Configure the AWS Provider
provider "aws" {
  region  = var.region
  profile = "terra-admin"
}

# create vpc
module "vpc" {
  source                       = "../Modules/vpc"
  region                       = var.region
  project_name                 = var.project_name
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr
}

#create nat-gateway
module "nat-gateway" {
  source                     = "../Modules/nat-gateway"
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
}

# create security groups 
module "security-groups" {
  source = "../Modules/security-groups"
  vpc_id = module.vpc.vpc_id
}

# create ecs task execution role

module "ecs_tasks_execution_role" {
  source       = "../Modules/ecs-tasks-execution-role"
  project_name = module.vpc.project_name
}


# request ssl certificate through acm
module "acm" {
  source                    = "../Modules/acm"
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names

}


