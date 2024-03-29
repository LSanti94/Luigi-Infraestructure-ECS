# environment variables
variable "region" {}
variable "project_name" {}
variable "environment" {}

# vpc
variable "vpc_cidr" {}
variable "public_subnet_az1_cidr" {}
variable "public_subnet_az2_cidr" {}
variable "public_route_table_cidr" {}
variable "private_app_subnet_az1_cidr" {}
variable "private_app_subnet_az2_cidr" {}
variable "private_data_subnet_az1_cidr" {}
variable "private_data_subnet_az2_cidr" {}

# nat-gateway
variable "private_route_table_az1_cidr" {}
variable "private_route_table_az2_cidr" {}

# SG
variable "SG_cidr_ingress_egress_IPV4" {}
variable "ssh_ip" {}

# rds
variable "database_snapshot_identifier" {}
variable "database_instance_class" {}
variable "database_instance_identifier" {}
variable "multi_az_deployment" {}

# acm
variable "domain_name" {}
variable "alternative_names" {}

# alb
variable "target_type" {}

# s3
variable "env_file_bucket_name" {}
variable "env_file_name" {}

# ecs
variable "architecture" {}
variable "container_image" {}

# route-53
variable "record_name" {}