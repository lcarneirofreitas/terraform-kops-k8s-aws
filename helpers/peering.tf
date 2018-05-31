module "vpc_peering" {
  source = "github.com/thomasbiddle/tf_aws_vpc_peering"

  peer_from_vpc_name = "main"
  peer_to_vpc_name   = "Default VPC"
  
  peer_from_vpc_id = "vpc-57363b2c"
  peer_to_vpc_id   = "vpc-a3c27edb"
  
  peer_from_route_tables     = ["rtb-f8e61a87"]
  peer_to_route_tables   = ["rtb-62eab718"]
}
