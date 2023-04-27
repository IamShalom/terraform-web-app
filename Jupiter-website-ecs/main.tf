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


# create application load balancer
module "alb" {
  source                = "../Modules/alb"
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security-groups.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  vpc_id                = module.vpc.vpc_id
  certificate_arn       = module.acm.certificate_arn
}

# create ecs service
module "ecs" {
  source                       = "../Modules/ecs"
  project_name                 = module.vpc.project_name
  ecs-tasks-execution-role-arn = module.ecs_tasks_execution_role.ecs-tasks-execution-role-arn
  container_image              = var.container_image
  region                       = module.vpc.region
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  ecs_security_group_id        = module.security-groups.ecs_security_group_id
  alb_target_group_arn         = module.alb.alb_target_group_arn
}

# create app auto scaling group
module "asg" {
  source           = "../Modules/asg"
  ecs_cluster_name = module.asg.ecs_cluster_name
  ecs_service_name = module.asg.ecs_service_name
}

# create route-53 record
module "route-53" {
  source                             = "../Modules/route-53"
  domain_name                        = module.acm.domain_name
  record_name                        = var.record_name
  application_load_balancer_dns_name = module.alb.application_load_balancer_dns_name
  application_load_balancer_zone_id  = module.alb.application_load_balancer_zone_id
}

# output the url for the website
output "website_url" {
  value = join("", ["https://", var.record_name, ".", var.domain_name])
}
