locals {
  env = var.env
}

module "ec2" {
  source = "./modules"

  key_name              = var.key_name
  ami_id                = var.ami_id
  instance_type         = var.instance_type
  volume_size           = var.volume_size
  volume_type           = var.volume_type
  delete_on_termination = var.delete_on_termination
  encrypted             = var.encrypted

  aws_region                = var.aws_region
  env                       = var.env
  vpc_cidr_block            = var.vpc_cidr_block
  vpc_name                  = "${local.env}-${var.vpc_name}"
  igw_name                  = "${local.env}-${var.igw_name}"
  public_subnet_count       = var.public_subnet_count
  public_subnet_cidr_block  = var.public_subnet_cidr_block
  availability_zones        = var.availability_zones
  public_subnet_name        = "${local.env}-${var.public_subnet_name}"
  private_subnet_count      = var.private_subnet_count
  private_subnet_cidr_block = var.private_subnet_cidr_block
  private_subnet_name       = "${local.env}-${var.private_subnet_name}"
  public_route_table_name   = "${local.env}-${var.public_route_table_name}"
  private_route_table_name  = "${local.env}-${var.private_route_table_name}"
  eip_name                  = "${local.env}-${var.eip_name}"
  nat_gateway_name          = "${local.env}-${var.nat_gateway_name}"
  eks-sg                    = var.eks-sg
}