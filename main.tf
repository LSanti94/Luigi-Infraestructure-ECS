locals {
  region       = var.region
  project_name = var.project_name
  environment  = var.environment
}

# Create vpc module
module "vpc" {
  source                       = "git@github.com:LSanti94/terraform-modules.git//vpc"
  region                       = local.region
  project_name                 = local.project_name
  environment                  = local.environment
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  public_route_table_cidr      = var.public_route_table_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr
}

#create nat_gateway module
module "nat_gateway" {
  source                       = "git@github.com:LSanti94/terraform-modules.git//nat-gateway"
  project_name                 = local.project_name
  environment                  = local.environment
  public_subnet_az1_id         = module.vpc.public_subnet_az1_id
  public_subnet_az2_id         = module.vpc.public_subnet_az2_id
  internet_gateway             = module.vpc.internet_gateway
  vpc_id                       = module.vpc.vpc_id
  private_route_table_az1_cidr = var.private_route_table_az1_cidr
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az1_id
  private_data_subnet_az1_id   = module.vpc.private_data_subnet_az1_id
  private_route_table_az2_cidr = var.private_route_table_az2_cidr
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az2_id   = module.vpc.private_data_subnet_az2_id
}

# Create security_group module
module "security_group" {
  source                      = "git@github.com:LSanti94/terraform-modules.git//security-groups"
  project_name                = local.project_name
  environment                 = local.environment
  vpc_id                      = module.vpc.vpc_id
  SG_cidr_ingress_egress_IPV4 = var.SG_cidr_ingress_egress_IPV4
  ssh_ip                      = var.ssh_ip
}

# Create rds module
module "rds" {
  source                       = "git@github.com:LSanti94/terraform-modules.git//rds"
  project_name                 = local.project_name
  environment                  = local.environment
  private_data_subnet_az1_id   = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id   = module.vpc.private_data_subnet_az2_id
  database_snapshot_identifier = var.database_snapshot_identifier
  database_instance_class      = var.database_instance_class
  availability_zone_1          = module.vpc.availability_zone_1
  database_instance_identifier = var.database_instance_identifier
  multi_az_deployment          = var.multi_az_deployment
  database_security_group_id   = module.security_group.database_security_group_id
}

# request ssl certificate
module "ssl_certificate" {
  source            = "git@github.com:LSanti94/terraform-modules.git//acm"
  domain_name       = var.domain_name
  alternative_names = var.alternative_names
}

# Create alb
module "alb" {
  source                = "git@github.com:LSanti94/terraform-modules.git//alb"
  project_name          = local.project_name
  environment           = local.environment
  alb_security_group_id = module.security_group.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  target_type           = var.target_type
  vpc_id                = module.vpc.vpc_id
  certificate_arn       = module.ssl_certificate.certificate_arn
}

# Create s3
module "s3" {
  source               = "git@github.com:LSanti94/terraform-modules.git//s3"
  project_name         = local.project_name
  env_file_bucket_name = var.env_file_bucket_name
  env_file_name        = var.env_file_name

}

# Create ecs task execution role
module "ecs_task_execution_role" {
  source               = "git@github.com:LSanti94/terraform-modules.git//iam-role"
  project_name         = local.project_name
  env_file_bucket_name = module.s3.env_file_bucket_name
  environment          = local.environment
}

# Create ecs cluster, task definition and service
module "ecs" {
  source                       = "git@github.com:LSanti94/terraform-modules.git//ecs"
  project_name                 = local.project_name
  environment                  = local.environment
  ecs_task_execution_role_arn  = module.ecs_task_execution_role.ecs_task_execution_role_arn
  architecture                 = var.architecture
  container_image              = var.container_image
  env_file_bucket_name         = module.s3.env_file_bucket_name
  env_file_name                = module.s3.env_file_name
  region                       = local.region
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  app_server_security_group_id = module.security_group.app_server_security_group_id
  alb_target_group_arn         = module.alb.alb_target_group_arn
}