###########
# Variables
###########
variable "AWS_REGION" { default = "us-east-1" }
variable "PATH_TO_PRIVATE_KEY" { default = "mykey" }
variable "PATH_TO_PUBLIC_KEY" { default = "mykey.pub" }
variable "VPC_NAME" { default = "k8s-vpc" }
variable "PUBLIC_NET" { default = "k8s-public" }
variable "PRIVATE_NET" { default = "k8s-private" }

