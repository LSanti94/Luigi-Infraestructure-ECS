terraform {
  backend "s3" {
    bucket         = "terraform-back-state"
    key            = "terraform-module/terraform.tfstate"
    region         = "eu-west-2"
    profile        = "luigi"
    dynamodb_table = "terraform-state-lock"
  }
}