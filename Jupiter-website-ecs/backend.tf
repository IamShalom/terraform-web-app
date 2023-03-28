# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket  = "terrraform-aws-statefile"
    key     = "jupiter-website-ecs.tfstate"
    region  = "us-east-1"
    profile = "terra-admin"
  }
}