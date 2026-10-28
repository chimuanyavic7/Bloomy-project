key_name      = "home-lab"
ami_id        = "ami-0303e2e4a29f041a3" 
instance_type = "t3.small"

env                       = "dev"
aws_region                = "eu-central-1"
vpc_cidr_block            = "10.16.0.0/16"
vpc_name                  = "eks-vpc"
igw_name                  = "eks-igw"
public_subnet_count       = 2
public_subnet_cidr_block  = ["10.16.0.0/20", "10.16.16.0/20"]
availability_zones        = ["eu-central-1a", "eu-central-1b"]
public_subnet_name        = "eks-public-subnet"
private_subnet_count      = 2
private_subnet_cidr_block = ["10.16.128.0/20", "10.16.144.0/20"]
private_subnet_name       = "eks-private-subnet"
public_route_table_name   = "eks-public-rt"
private_route_table_name  = "eks-private-rt"
eip_name                  = "eks-eip"
nat_gateway_name          = "eks-ngw"
eks-sg                    = "eks-sg"

volume_size           = 20
volume_type           = "gp3"
delete_on_termination = true
encrypted             = true