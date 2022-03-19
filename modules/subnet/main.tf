# to create VPC netwrok on AWS
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
      Name: "${var.env_perfix}-vpc"
    }
  
}


# To create subnet in vpc netwrok on AWS
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = var.vpc_id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
      Name:  "${var.env_perfix}-subnet-1"
    }
  
}

resource "aws_internet_gateway" "myapp-internet-gateway" {
  vpc_id = var.vpc_id
  tags = {
     Name: "${var.env_perfix}-igw"
  }
}

# route table 
resource "aws_route_table" "myapp-route-table" {
  route_table = var.route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-internet-gateway.id
  }
  tags = {
     Name: "${var.env_perfix}-rtb"
  }
}


