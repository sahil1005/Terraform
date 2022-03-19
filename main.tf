provider "aws" {
  region = "eu-west-3"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_perfix {}
variable my_ip {}

# to create VPC netwrok on AWS
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
      Name: "${var.env_perfix}-vpc"
    }
  
}


module "myapp-subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_perfix = var.env_perfix
  vpc_id = aws_vpc.myapp-vpc.id
  route_table_id = aws_vpc.myapp-vpc.route_table_id

}


# To create subnet in vpc netwrok on AWS
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
      Name:  "${var.env_perfix}-subnet-1"
    }
  
}

# route table 
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-internet-gateway
  }
  tags = {
     Name: "${var.env_perfix}-rtb"
  }
}

# internet gateway 
resource "aws_internet_gateway" "myapp-internet-gateway" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
     Name: "${var.env_perfix}-igw"
  }
}

#route table
resource "aws_route_table_association" "a-rbt-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table
  
}




# firewall rules to access EC2 
resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
     Name: "${var.env_perfix}-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {    
    most_recent = true
    owners = ["amazon"] 
    filter {
      name = "name"
      value = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }  
}

resource "aws_key_pair" "shh-key" {
    key_name = "server-key"
    public_key = ""
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = "server-key-pair"

    user_data = <<EOF
                  #!/bin/bash
                  sudo yum update -y && sudo yum install -y docker
                  sudo systemctl start docker
                  sudo usermode -aG docker ec2-user
                  docker run -p 8080:80 nginx 
                EOF
/*
#alternative
    user_data = file("entry-script.sh")  
*/                         

    tags = {
      Name:  "${var.env_perfix}-server"
    }
  
}