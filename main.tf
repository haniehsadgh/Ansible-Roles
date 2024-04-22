# Haniehsadat Gholamhosseini

terraform {
#  backend "s3" {
#    bucket    = "hanieh-terraform-state-backend"
#    key       = "terraform.tfstate"
#    region    = "us-west-2"
#    encrypt   = true
#    dynamodb_table     = "hanieh-terraform-state-lock"
#  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Module for Security Group
module "security_groups" {
  source             = "./modules/terraform_security_group"
  vpc_id	     = aws_vpc.main.id
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}


# Create a VPC
#resource "aws_vpc" "example" {
#  cidr_block = "10.0.0.0/16"
#}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block     = var.base_cidr_block
  instance_tenancy       = "default"
  enable_dns_hostnames   = true

  tags   = {
        Name = "main"
  }
}

variable "base_cidr_block" {
  description = "default cidr block for vpc"
  default     = "10.0.0.0/16"
}

# Creare a public subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main"
  }
}

# Create a private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-ipg"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-route"
  }
}

# Create a private routing table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# get the most recent ami for Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "local_key" {
  key_name   = "demo_key"
  public_key = file("~/demo_key.pem.pub")
}

# public ec2 instance
resource "aws_instance" "ubuntu" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id

  tags = {
    Name = "ubuntu-public"
  }

  key_name               = aws_key_pair.local_key.key_name
  vpc_security_group_ids = [module.security_groups.sg_main_id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 10
  }
}

# ec2 instance in private subnet!
resource "aws_instance" "private" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id

  tags = {
    Name = "ubuntu-private"
  }

  key_name               = aws_key_pair.local_key.key_name
  vpc_security_group_ids = [module.security_groups.sg_private_id]
  subnet_id              = aws_subnet.private.id

  root_block_device {
    volume_size = 10
  }
}

# Output the vpc to use in the security group module 
output "vpc_id" {
  value = aws_vpc.main.id
}

# output public ip and private address of the 2 instances
output "pu_ec2_ip" {
  value = aws_instance.ubuntu.public_ip
}

output "pv_ec2_ip" {
  value = aws_instance.private.public_ip
}

locals {
  project_name	= "acit4640_as3"
  public_ec2_ip = aws_instance.ubuntu.public_ip
  private_ec2_ip = aws_instance.private.public_ip
}


# Create Ansible Inventory file
# Specify the ssh key and user and the servers for each server type
resource "local_file" "inventory" {
  content = <<-EOF
  all:
    vars:
      ansible_ssh_private_key_file: "./demo_key.pem"
      ansible_user: ubuntu
    hosts:
      ubuntu-public:
        ansible_host: ${local.public_ec2_ip}
      ubuntu-private:
        ansible_host: ${local.private_ec2_ip}
  EOF

  filename = "./as3-files-4640-w24/hosts.yml"

}

# Generate Ansible configuration file
# Configure Ansible to use the inventory file created above and set ssh options
# -----------------------------------------------------------------------------
resource "local_file" "ansible_config" {
  content = <<-EOT
  [defaults]
  inventory = hosts.yml
  stdout_callback = debug
  private_key_file = "./demo_key.pem"

  [ssh_connection]
  host_key_checking = False
  ssh_common_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

  EOT

  filename = "./as3-files-4640-w24/ansible.cfg"

}

