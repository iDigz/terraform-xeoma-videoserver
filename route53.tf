data "aws_route53_zone" "this" {
  name         = "aws.mydomain.ru."
  private_zone = false
}

resource "aws_eip" "this" {
  instance = module.ec2.id[0]
  vpc      = true
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "cctv.aws.mydomain.ru"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.this.public_ip]
}

