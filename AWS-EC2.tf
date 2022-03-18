provider "aws" {
  region = "eu-west-3"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_perfix {}
variable my_ip {}
variable instance_type {}

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
alternative
    user_data = file("entry-script.sh")  
*/                         

    tags = {
      Name:  "${var.env_perfix}-server"
    }
  
}