terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.30.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

#create vpc

resource "aws_vpc" "color-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "color-vpc"
  }
}

#create public subnet and private subnet

resource "aws_subnet" "color-public-subnet-1a" {
  vpc_id                  = aws_vpc.color-vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "color-public-subnet-1a"
  }
}

resource "aws_subnet" "color-private-subnet-2a" {
  vpc_id            = aws_vpc.color-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  #map_public_ip_on_launch = true

  tags = {
    Name = "color-private-subnet-2a"
  }
}


resource "aws_subnet" "color-public-subnet-1b" {
  vpc_id                  = aws_vpc.color-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "color-public-subnet-1b"
  }
}

resource "aws_subnet" "color-private-subnet-2b" {
  vpc_id            = aws_vpc.color-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
  #map_public_ip_on_launch = true

  tags = {
    Name = "color-private-subnet-2b"
  }
}

#create interget gateway

resource "aws_internet_gateway" "color_gw" {
  vpc_id = aws_vpc.color-vpc.id

  tags = {
    Name = "color_gw"
  }
}

#create public route table

resource "aws_route_table" "color_public_route" {
  vpc_id = aws_vpc.color-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.color_gw.id
  }

  tags = {
    Name = "color_public_route"
  }
}

resource "aws_route_table_association" "subnet_associate_1a" {
  subnet_id      = aws_subnet.color-public-subnet-1a.id
  route_table_id = aws_route_table.color_public_route.id
}

resource "aws_route_table_association" "subnet_associate_2a" {
  subnet_id      = aws_subnet.color-public-subnet-1b.id
  route_table_id = aws_route_table.color_public_route.id
}

#create private route table 

resource "aws_route_table" "color_private_route" {
  vpc_id = aws_vpc.color-vpc.id

  tags = {
    Name = "color_private_route"
  }
}

resource "aws_route_table_association" "subnet_associate_1b" {
  subnet_id      = aws_subnet.color-private-subnet-2a.id
  route_table_id = aws_route_table.color_private_route.id
}

resource "aws_route_table_association" "subnet_associate_2b" {
  subnet_id      = aws_subnet.color-private-subnet-2b.id
  route_table_id = aws_route_table.color_private_route.id
}

#create security group

resource "aws_security_group" "color_security_group" {
  name        = "color_security_group"
  description = "Allow 22 and 80 inbound traffic"
  vpc_id      = aws_vpc.color-vpc.id

  ingress {
    description = "22 from outside"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }


  ingress {
    description = "80 from outside"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "allow_80_22"
  }
}

#create launch template

resource "aws_launch_template" "mumbai" {
  name = "mumbai"
  instance_type = "t2.micro"
  image_id = "ami-03f4878755434977f"
  key_name = aws_key_pair.color-key.id
  vpc_security_group_ids = [aws_security_group.color_security_group.id]
   tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "mumbai-asg"
    }
  }


  user_data = filebase64("bin.sh")
}

#key pair 

resource "aws_key_pair" "color-key" {
  key_name   = "color-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDPVIfZnBFzCKjlv0A/5cJzESINxal+o6qstI6uZTADAK7lA8q07HboDJCZsiUuk5twgjUXOixSL2Lel6K3qVLyC490vhendZQ2+FvmrqOHW0GCaorLzjPyi7yoO0IwUvOttiibkC8kNcIhR2E2CPBuS3aa5s7hYCGAT/hsL4C+kaDeP7bO+zLOobPTxC6q7fLWgTEcUdNY0Kx7dnLRG44yKZXTu9zUy/ojy2+GlO0x1Jlsi++9JJ6Vvx1KGaL2OQegVFkvrALoKgDkrVg4snNjDrrB0RyZhkoPrdqXYJ9IGNyVnhSKPC0qIa2ciWwGJAuIbbFRFV/Zy4hi5/Ltf0SB5IbLGAujjKK+mKvS3CXiaW//9cmi8bRXeqs0QhjCC6T5+bztsAN6bbgrPxklOknWMmNbl7EbpgYFIXH3vZqbnJrjkp0M7hyGj5zvqKJl29hXCOKN2jrcgiiwFjazGZlCi1P93tUn+zRSiexlVC+cKOoYyKyi23+jf7MEaRPj0U0= karth@DESKTOP-J9H78IA"
} 

#create auto scalling group


resource "aws_autoscaling_group" "color_scalling_asg" {
  vpc_zone_identifier  = [aws_subnet.color-public-subnet-1a.id, aws_subnet.color-public-subnet-1b.id]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 2
  target_group_arns   = [aws_lb_target_group.color_targetgrp.arn]

 launch_template {
    id      = aws_launch_template.mumbai.id
    version = "$Latest"
  }
}

# create load balancer 

resource "aws_lb" "color_webapk" {
  name               = "color-webapk"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.color_security_group.id]
  subnets            = [aws_subnet.color-public-subnet-1a.id, aws_subnet.color-public-subnet-1b.id]

  #enable_deletion_protection = true


  tags = {
    Environment = "production"
  }
}

# craete load balancer listener

resource "aws_lb_listener" "color_listener" {
  load_balancer_arn = aws_lb.color_webapk.arn
  port              = "80"
  protocol          = "HTTP"
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.color_targetgrp.arn
  }
}

# create target group lb

resource "aws_lb_target_group" "color_targetgrp" {
  name        = "color-targetgrp"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.color-vpc.id
}