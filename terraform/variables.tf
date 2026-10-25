variable "aws_region" {}

variable "key_name" {}
variable "ami_id" {}
variable "instance_type" {}

variable "volume_size" {}
variable "volume_type" {}
variable "delete_on_termination" {}
variable "encrypted" {}


variable "vpc_cidr_block" {}
variable "vpc_name" {}
variable "env" {}
variable "igw_name" {}
variable "public_subnet_count" {}
variable "public_subnet_cidr_block" {
  type = list(string)
}
variable "availability_zones" {
  type = list(string)
}
variable "public_subnet_name" {}
variable "private_subnet_count" {}
variable "private_subnet_cidr_block" {
  type = list(string)
}
variable "private_subnet_name" {}
variable "public_route_table_name" {}
variable "private_route_table_name" {}
variable "eip_name" {}
variable "nat_gateway_name" {}
variable "eks-sg" {}

