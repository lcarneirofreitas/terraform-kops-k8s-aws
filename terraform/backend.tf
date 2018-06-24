####################
# storage tfstate s3
####################
terraform {
  backend "s3" {
    bucket = "terraform-state-$DOMAIN_K8S"
    key = "terraform/terraform.tfstate"
  }
}
