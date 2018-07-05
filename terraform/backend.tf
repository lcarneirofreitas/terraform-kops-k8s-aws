####################
# storage tfstate s3
####################
terraform {
  backend "s3" {
    bucket = "terraform-state-domain_k8s"
    key = "terraform/terraform.tfstate"
  }
}
