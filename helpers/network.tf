##############
# Internet VPC
##############
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags {
        Name = "main"
    }
}

#############
# Internet GW
#############
resource "aws_eip" "nat" {
  vpc = true
}
resource "aws_internet_gateway" "main-gw" {
    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "main"
    }
}
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.main-public-1.id}"
  depends_on = ["aws_internet_gateway.main-gw"]
}

#########
# Subnets
#########
resource "aws_subnet" "main-public-1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.70.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "${var.AWS_REGION}a"

    tags {
        Name = "${var.PUBLIC_NET}-1"
    }
}

resource "aws_subnet" "main-private-1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.71.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "${var.AWS_REGION}a"

    tags {
        Name = "${var.PRIVATE_NET}-1"
    }
}

##############
# Route Tables
##############
resource "aws_route_table" "main-public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.main-gw.id}"
    }

    tags {
        Name = "main-public-1"
    }
}
resource "aws_route_table" "main-private" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
    }

    tags {
        Name = "main-private-1"
    }
}

####################
# Route Associations
####################
resource "aws_route_table_association" "main-public-1-a" {
    subnet_id = "${aws_subnet.main-public-1.id}"
    route_table_id = "${aws_route_table.main-public.id}"
}
resource "aws_route_table_association" "main-private-1-a" {
    subnet_id = "${aws_subnet.main-private-1.id}"
    route_table_id = "${aws_route_table.main-private.id}"
}

output "vpc_id" {
    description = "The ID of the VPC"
    value = "${aws_vpc.main.id}"
}
