resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr_block
    instance_tenancy = "default"

    enable_dns_hostnames = true
    enable_dns_support   = true
    
    tags = {
        "Name" = var.vpc_name
        "Env"  = var.env  
    }
}


resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        "Name" = var.igw_name
        "Env"  = var.env  
    }

    depends_on = [ aws_vpc.vpc ]
}


resource "aws_subnet" "public_subnet" {
    count = var.public_subnet_count
    vpc_id = aws_vpc.vpc.id
    cidr_block = element(var.public_subnet_cidr_block, count.index)
    availability_zone = element(var.availability_zones, count.index)

    map_public_ip_on_launch = true

    tags = {
        "Name" = var.public_subnet_name
        "Env"  = var.env  
    }

    depends_on = [ aws_vpc.vpc ]
}

resource "aws_subnet" "private_subnet" {
    count = var.private_subnet_count
    vpc_id = aws_vpc.vpc.id
    cidr_block = element(var.private_subnet_cidr_block, count.index)
    availability_zone = element(var.availability_zones, count.index)

    map_public_ip_on_launch = false

    tags = {
        "Name" = var.private_subnet_name
        "Env"  = var.env  
    }

    depends_on = [ aws_vpc.vpc ]
}


resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        "Name" = var.public_route_table_name
        "Env"  = var.env  
        
    }

    depends_on = [ aws_vpc.vpc ]
}


resource "aws_route_table_association" "public_subnet_route_table_association" {
    count = var.public_subnet_count
    subnet_id = element(aws_subnet.public_subnet[*].id, count.index)
    route_table_id = aws_route_table.public_rt.id

    depends_on = [ aws_vpc.vpc, aws_subnet.public_subnet ]
}

resource "aws_eip" "ngw_eip" {
   domain = "vpc"

   tags = {
        "Name" = var.eip_name
        "Env"  = var.env  
   }   

   depends_on = [ aws_vpc.vpc ]
}


resource "aws_nat_gateway" "ngw" {
    allocation_id = aws_eip.ngw_eip.id
    subnet_id = element(aws_subnet.public_subnet[*].id, 0)

    tags = {
        "Name" = var.nat_gateway_name
        "Env"  = var.env  
    }   

    depends_on = [ aws_eip.ngw_eip, aws_vpc.vpc ]
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.ngw.id
    }

    tags = {
        "Name" = var.private_route_table_name
        "Env"  = var.env  
        
    }

    depends_on = [ aws_vpc.vpc ]
}

resource "aws_route_table_association" "private_subnet_route_table_association" {
    count = var.private_subnet_count
    subnet_id = element(aws_subnet.private_subnet[*].id, count.index)
    route_table_id = aws_route_table.private_rt.id

    depends_on = [ aws_vpc.vpc, aws_subnet.private_subnet ]
}

