terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.37.0"
    }
  }
}

locals {
  NAME = "tf-poc"

  //create the keypair before applying this 
  KEY_NAME = "my-key-pair"
  //Amazon Linux 2023 AMI (64-bit (x86)) without uefi. 
  //T2 Micro doesnt support uefi
  AMI = "ami-0cf10cdf9fcd62d37"
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}



# Create a VPC
resource "aws_vpc" "tfvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.NAME}-vpc"
    App  = var.app-name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "tfvpc-gw" {
  vpc_id = aws_vpc.tfvpc.id
  tags = {
    Name = "${local.NAME}-vpc-gw"
    App  = var.app-name
  }
}

# Create a Public Subnet
resource "aws_subnet" "tfvpc-pubsubnet" {
  vpc_id     = aws_vpc.tfvpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${local.NAME}-vpc-pubsubnet"
    App  = var.app-name
  }
}

# Create a Private Subnet
resource "aws_subnet" "tfvpc-pvtsubnet" {
  vpc_id     = aws_vpc.tfvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "${local.NAME}-vpc-pvtsubnet"
    App  = var.app-name
  }
}


# Public Routing table for the VPC
resource "aws_route_table" "tfvpc-pubrt" {
  vpc_id = aws_vpc.tfvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfvpc-gw.id
  }
  tags = {
    Name = "${local.NAME}-tfvpc-pubrt"
    App  = var.app-name
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tfvpc-pubsubnet.id
  route_table_id = aws_route_table.tfvpc-pubrt.id
}


# Public Security Group
resource "aws_security_group" "pub-ec2-sg" {
  vpc_id = aws_vpc.tfvpc.id
  tags = {
    Name = "${local.NAME}-pub-ec2-sg"
    App  = var.app-name
  }
}
# Security Group Inbound Rule
resource "aws_vpc_security_group_ingress_rule" "pub-ec2-sg-ingree" {
  security_group_id = aws_security_group.pub-ec2-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
# Security Group Outbound Rule
resource "aws_vpc_security_group_egress_rule" "pub-ec2-sg-egree" {
  security_group_id = aws_security_group.pub-ec2-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "All"
}

# Create EC2 Inside PUB Subnet
resource "aws_instance" "tfpoc-pub" {
  ami                         = local.AMI
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tfvpc-pubsubnet.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.pub-ec2-sg.id]
  key_name                    = local.KEY_NAME
  tags = {
    Name = "${local.NAME}-ec2-pub"
    App  = var.app-name
  }
}


resource "aws_eip" "eip_nat_gateway" {
}

# Nat gateway will allow outbound from pvt subset via pub subnet
resource "aws_nat_gateway" "ng" {
  allocation_id = aws_eip.eip_nat_gateway.id
  subnet_id     = aws_subnet.tfvpc-pubsubnet.id

  tags = {
    Name = "${local.NAME}-ng"
    App  = var.app-name
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.tfvpc-gw]
}

# Private Routing table for the VPC
resource "aws_route_table" "tfvpc-pvtrt" {
  vpc_id = aws_vpc.tfvpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ng.id
  }
  tags = {
    Name = "${local.NAME}-tfvpc-pvtrt"
    App  = var.app-name
  }
}
resource "aws_route_table_association" "pvt" {
  subnet_id      = aws_subnet.tfvpc-pvtsubnet.id
  route_table_id = aws_route_table.tfvpc-pvtrt.id
}


# Private Security Group
resource "aws_security_group" "pvt-ec2-sg" {
  vpc_id = aws_vpc.tfvpc.id
  tags = {
    Name = "${local.NAME}-pvt-ec2-sg"
    App  = var.app-name
  }
}
# Security Group Inbound Rule
resource "aws_vpc_security_group_ingress_rule" "pvt-ec2-sg-ingree" {
  security_group_id = aws_security_group.pvt-ec2-sg.id
  cidr_ipv4         = "10.0.0.0/16" //All interal VPC IP
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
# Security Group Outbound Rule
resource "aws_vpc_security_group_egress_rule" "pvt-ec2-sg-egree" {
  security_group_id = aws_security_group.pvt-ec2-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "All"
}

# Create EC2 Inside PVT Subnet
resource "aws_instance" "tfpoc-pvt" {
  ami             = local.AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.tfvpc-pvtsubnet.id
  security_groups = [aws_security_group.pvt-ec2-sg.id]
  key_name        = local.KEY_NAME
  tags = {
    Name = "${local.NAME}-ec2-pvt"
    App  = var.app-name
  }
}
