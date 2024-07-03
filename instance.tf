terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.36.0"
    }
  }
}

# Configure the AWS provider

provider "aws" {
  region = var.region
  default_tags {
   tags = {
     Environment = "Test"
     Owner       = "Darelle"
     Project     = "Splunk-Documentation"
  }
 }
}

# The below code is for creating a vpc

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  instance_tenancy     = "default"
}

# Create Public Subnet for the jenkins server

resource "aws_subnet" "subnet-public-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = var.AZ1

}

# Create IGW for internet connection 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

# Creating Route table 

resource "aws_route_table" "public-routetab" {
  vpc_id = aws_vpc.vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.igw.id
  }

}

# Associating route tabe to public subnet

resource "aws_route_table_association" "public-routetab-subnet-1" {
  subnet_id      = aws_subnet.subnet-public-1.id
  route_table_id = aws_route_table.public-routetab.id

}

# Generate a secure key using a rsa algorithm

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Creating the keypair in aws

resource "aws_key_pair" "ec2_key" {
  key_name   = var.keypair_name                 
  public_key = tls_private_key.ec2_key.public_key_openssh 
}

# Save the .pem file locally for remote connection

resource "local_file" "ssh_key" {
  filename        = var.keypair_location
  content         = tls_private_key.ec2_key.private_key_pem
  file_permission = "0400"
}

# ~~~~~~~~~ Security group for the splunk server and forwarder ~~~~~~~~ #

resource "aws_security_group" "ec2_allow_rule" {

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "allow ssh,http,https"
  }

}

# ~~~~~~ Create an ec2 instance for the splunk server and forwarder ~~~~~~~ #

locals {
  instances = {
    splunk-forwarder = {name = "splunk-forwrder", instance-type = "${var.instance_type_forwarder}", userdata = "${file("userdata_forwarder.sh")}"},
    splunk-server    = {name = "splunk-server", instance-type = "${var.instance_type_server}", userdata = "${file("userdata_server.sh")}"},
  }
  
}

resource "aws_instance" "ec2-instance" {
  for_each = local.instances
  ami                    = var.aws_ami
  instance_type          = each.value.instance-type
  subnet_id              = aws_subnet.subnet-public-1.id
  vpc_security_group_ids = ["${aws_security_group.ec2_allow_rule.id}"]
  user_data              = each.value.userdata
  key_name               = aws_key_pair.ec2_key.key_name

  tags = {
    Name = each.value.name
  }

 }

# ~~~ To delete the ec2-key-1.pem file while destroying this infrastructure ~~~ #

resource "null_resource" "clean_up" {

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ec2-key-1.pem"
  }
}

# ~~~~~~ Print the link to be redirected to the jenkins server ~~~~~ #

output "INFO" {
  value = "AWS Resources and splunk forwarder has been provisioned. Go to http://${aws_instance.ec2-instance["splunk-forwarder"].public_ip}:8000"
}
output "INFO-2" {
  value = "AWS Resources and splunk Server has been provisioned. Go to http://${aws_instance.ec2-instance["splunk-server"].public_ip}:8000"
}