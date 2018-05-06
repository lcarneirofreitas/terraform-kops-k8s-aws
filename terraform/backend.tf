####################
# storage tfstate s3
####################
terraform {
  backend "s3" {
    bucket = "terraform-state-collystore"
    key = "terraform/terraform.tfstate"
  }
}
