provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-1"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_ssm_parameter" "this" {
  name        = "/dev/${var.instance_name}/private_key_pem"
  description = "PEM key for access ti instance"
  type        = "SecureString"
  value       = tls_private_key.this.private_key_pem
}
resource "aws_key_pair" "this" {
  key_name   = "${var.instance_name}-kp"
  public_key = tls_private_key.this.public_key_openssh
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_ami" "ubuntu-18_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "${var.instance_name}-sg"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks
  egress_with_cidr_blocks  = var.egress_with_cidr_blocks
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name                   = var.instance_name
  instance_count         = var.instance_count
  ami                    = data.aws_ami.ubuntu-18_04.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  monitoring             = true
  vpc_security_group_ids = [module.security_group.this_security_group_id]
  subnet_id              = tolist(data.aws_subnet_ids.all.ids)[0]
  ebs_block_device       = var.ebs_block_device
  user_data              = file("user_data.sh")

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
