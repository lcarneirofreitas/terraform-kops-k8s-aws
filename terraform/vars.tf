###########
# Variables
###########
variable "AWS_REGION" { default = "us-east-1" }
variable "PATH_TO_PRIVATE_KEY" { default = "mykey" }
variable "PATH_TO_PUBLIC_KEY" { default = "mykey.pub" }
variable "VPC_NAME" { default = "collystore-vpc" }
variable "PUBLIC_NET" { default = "collystore-public" }
variable "PRIVATE_NET" { default = "collystore-private" }

