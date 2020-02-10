variable "instance_name" {}
variable "instance_type" {}
variable "instance_count" {}
variable "ingress_with_cidr_blocks" {
  type = list(map(string))
}
variable "egress_with_cidr_blocks" {
  type = list(map(string))
}