provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "finance1_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "finance1-vpc"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "finance1_igw" {
  vpc_id = aws_vpc.finance1_vpc.id
}

# Create a subnet
resource "aws_subnet" "finance1_subnet" {
  vpc_id                  = aws_vpc.finance1_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Create a route table and route
resource "aws_route_table" "finance1_route_table" {
  vpc_id = aws_vpc.finance1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.finance1_igw.id
  }
}

resource "aws_route_table_association" "finance1_rta" {
  subnet_id      = aws_subnet.finance1_subnet.id
  route_table_id = aws_route_table.finance1_route_table.id
}

# Create a security group
resource "aws_security_group" "finance1_sg" {
  name        = "finance1-sg"
  description = "Allow SSH, HTTP, and MySQL"
  vpc_id      = aws_vpc.finance1_vpc.id

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
    cidr_blocks = ["0.0.0.0/0"] # App access
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

# Create EC2 instance
resource "aws_instance" "finance_ec2" {
  ami                         = "ami-084568db4383264d4" 
  instance_type               = "t2.large"
  subnet_id                   = aws_subnet.finance1_subnet.id
  vpc_security_group_ids      = [aws_security_group.finance1_sg.id]
  associate_public_ip_address = true
  key_name                    = "project" 

  tags = {
    Name = "banking_project"
  }

  user_data = <<-EOF
              sudo apt update -y
              sudo apt install docker.io -y
              sudo systemctl enable docker
              EOF
}

resource "aws_db_instance" "finance1_rds" {
  identifier              = "financeme1-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0.35" 
  instance_class          = "db.t3.medium"
  username                = "admin"
  password                = "Akshata1999" 
  db_subnet_group_name    = aws_db_subnet_group.finance1_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.finance1_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = true
}



resource "aws_subnet" "finance1_subnet_1" {
  vpc_id                  = aws_vpc.finance1_vpc.id
  cidr_block              = "10.0.100.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "finance1_subnet_2" {
  vpc_id                  = aws_vpc.finance1_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_db_subnet_group" "finance1_subnet1_group" {
  name       = "finance1-subnet-group-1"
  subnet_ids = [
    aws_subnet.finance1_subnet_1.id,
    aws_subnet.finance1_subnet_2.id
  ]

  tags = {
    Name = "Finance1 DB subnet group"
  }
}


