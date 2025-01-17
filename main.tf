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

resource "aws_iam_role" "this" {
  name = "${var.instance_name}-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "ssm_access_attachment" {
  role       = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name                        = var.instance_name
  instance_count              = var.instance_count
  ami                         = data.aws_ami.ubuntu-18_04.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  monitoring                  = true
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  user_data                   = file("user_data.sh")
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_ebs_volume" "this" {
  most_recent = true

  filter {
    name   = "volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "tag:Name"
    values = ["cctv"]
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/xvdb"
  volume_id   = data.aws_ebs_volume.this.id
  instance_id = module.ec2.id[0]
}
