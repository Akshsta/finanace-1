provider "aws" {
  region = "us-east-1"
}

# Toggle creation of components
variable "create_ec2" {
  description = "Set to true to create EC2 instance"
  type        = bool
  default     = true
}

variable "create_rds" {
  description = "Set to true to create RDS instance"
  type        = bool
  default     = true
}

variable "create_sg" {
  description = "Set to true to create Security Group"
  type        = bool
  default     = true
}

variable "create_subnet_group" {
  description = "Set to true to create RDS Subnet Group"
  type        = bool
  default     = true
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

# Security Group (conditionally created)
resource "aws_security_group" "finance1_sg" {
  count       = var.create_sg ? 1 : 0
  name        = "finance1-sg"
  description = "Allow SSH, HTTP, and MySQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance (only if create_ec2 = true)
resource "aws_instance" "finance_ec2" {
  count                       = var.create_ec2 ? 1 : 0
  ami                         = "ami-084568db4383264d4"
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = var.create_sg ? [aws_security_group.finance1_sg[0].id] : []
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

# Output EC2 public IP (fallback to default IP if not created)
output "finance_ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = var.create_ec2 && length(aws_instance.finance_ec2) > 0 ? aws_instance.finance_ec2[0].public_ip : "44.201.199.111"
}

# RDS Subnet Group (conditionally created)
resource "aws_db_subnet_group" "finance1_subnet_group" {
  count      = var.create_subnet_group ? 1 : 0
  name       = "finance1-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Finance1 DB subnet group"
  }
}

resource "random_pet" "name" {
  length = 2
}

# RDS MySQL Instance (only if create_rds = true)
resource "aws_db_instance" "finance1_rds" {
  count                   = var.create_rds ? 1 : 0
  identifier              = "financeme1-db-${random_pet.name.id}"  # unique suffix
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "Akshata1999"
  db_subnet_group_name    = var.create_subnet_group ? aws_db_subnet_group.finance1_subnet_group[0].name : ""
  vpc_security_group_ids  = var.create_sg ? [aws_security_group.finance1_sg[0].id] : []
  skip_final_snapshot     = true
  publicly_accessible     = true
}
