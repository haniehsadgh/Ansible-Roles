#Haniehsadat Gholamhosseini

variable "vpc_id" {
  description = "The VPC for instances"
}

# security group for public instance!
resource "aws_security_group" "main" {
  name           = "main_sg"
  vpc_id         = var.vpc_id
}

# security group for private instance!
resource "aws_security_group" "private" {
  name           = "private_sg"
  vpc_id         = var.vpc_id
}

# security group egress or outbound rules for public ec2 instance!
resource "aws_vpc_security_group_egress_rule" "main" {
# make this open to everything from everywhere
  security_group_id = aws_security_group.main.id
#  from_port      = 0
#  to_port        = 0
  ip_protocol    = "-1"
  cidr_ipv4      = "0.0.0.0/0"
}

# security group ingress or inbound rules for public ec2 instance !
resource "aws_vpc_security_group_ingress_rule" "ssh" {
# ssh and http in from everywhere
#  type          = "ingress"
security_group_id = aws_security_group.main.id
  from_port      = 22
  to_port        = 22
  ip_protocol    = "tcp"
  cidr_ipv4      = "0.0.0.0/0"
}

# security group ingress rules for public instance!
resource "aws_vpc_security_group_ingress_rule" "http" {
# ssh and http in from everywhere
#  type           = "ingress"
security_group_id = aws_security_group.main.id
  from_port      = 80
  to_port        = 80
  ip_protocol       = "tcp"
  cidr_ipv4    = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh-private" {
  #  type          = "ingress"
  security_group_id = aws_security_group.private.id
  from_port      = 22
  to_port        = 22
  ip_protocol    = "tcp"
  cidr_ipv4      = "0.0.0.0/0"  # This allows SSH from any IP
}

# security group ingress rules for private instance!
resource "aws_vpc_security_group_ingress_rule" "http-private" {
# ssh and http in from everywhere
#  type           = "ingress"
security_group_id = aws_security_group.private.id
  from_port      = 80
  to_port        = 80
  ip_protocol    = "tcp"
  cidr_ipv4      = "10.0.0.0/16"
}

# security group egress rules (outbound rule)for private instance !
resource "aws_vpc_security_group_egress_rule" "private" {
# make this open to everything from everywhere
#  type          = "egress"
security_group_id = aws_security_group.private.id
#  from_port      = 0
#  to_port        = 0
  ip_protocol    = "-1"
  cidr_ipv4      = "0.0.0.0/0"
}

output "sg_main_id" {
  value = aws_security_group.main.id
}

output "sg_private_id" {
  value = aws_security_group.private.id
}
