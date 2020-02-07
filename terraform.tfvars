instance_name  = "cctv-xeoma"
instance_type  = "t2.micro"
instance_count = 1
ebs_block_device = [
  {
    device_name           = "/dev/sdb"
    volume_type           = "gp2"
    volume_size           = "20"
    encrypted             = true
    delete_on_termination = false
  }
]
ingress_with_cidr_blocks = [
  {
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    description = "Xeoma-service port"
    cidr_blocks = "0.0.0.0/0"
  },
  {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH port"
    cidr_blocks = "0.0.0.0/0"
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS port"
    cidr_blocks = "0.0.0.0/0"
  }
]
egress_with_cidr_blocks = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    description = "All"
    cidr_blocks = "0.0.0.0/0"
  }
]