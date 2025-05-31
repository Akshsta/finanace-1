provider "aws" {
  region = "us-east-1"
}

# Use default VPC
data "aws_vpc" "default" {
  default = true
}

# Use existing subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group in default VPC
resource "aws_security_group" "finance1_sg" {
  name        = "finance1-sg"
  description = "Allow SSH, HTTP, and MySQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # App
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # MySQL
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance in default subnet
resource "aws_instance" "finance_ec2" {
  ami                         = "ami-084568db4383264d4"
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.finance1_sg.id]
  associate_public_ip_address = true
  key_name                    = "project"

  tags = {
    Name = "banking_project"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install docker.io -y
              sudo systemctl enable docker
              EOF
}

# RDS Subnet Group
resource "aws_db_subnet_group" "finance1_subnet_group" {
  name       = "finance1-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Finance1 DB subnet group"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "finance1_rds" {
  identifier              = "financeme1-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "Akshata1999"
  db_subnet_group_name    = aws_db_subnet_group.finance1_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.finance1_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = true
}
