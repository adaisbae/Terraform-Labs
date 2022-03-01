########################################################################
# Networking
########################################################################

resource "aws_vpc" "rds-vpc" {
  cidr_block           = "10.10.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "rds-vpc"
  }
}

resource "aws_subnet" "rds-subnet" {
  vpc_id                  = aws_vpc.rds-vpc.id
  cidr_block              = "10.10.0.0/25"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "rds-subnet"
  }
}

resource "aws_subnet" "rds-subnet-2" {
  vpc_id                  = aws_vpc.rds-vpc.id
  cidr_block              = "10.10.0.128/25"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"

  tags = {
    Name = "rds-subnet-2"
  }
}

resource "aws_internet_gateway" "rds-internet-gateway" {
  vpc_id = aws_vpc.rds-vpc.id

  tags = {
    Name = "rds-internet-gateway"
  }
}


resource "aws_route_table" "rds-public-routetable" {
  vpc_id = aws_vpc.rds-vpc.id

  tags = {
    Name = "rds-public-routetable"
  }
}


resource "aws_route" "default-route" {
  route_table_id         = aws_route_table.rds-public-routetable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rds-internet-gateway.id
}


resource "aws_route_table_association" "rds-public-assoc" {
  subnet_id      = aws_subnet.rds-subnet.id
  route_table_id = aws_route_table.rds-public-routetable.id
}


resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.rds-subnet.id, aws_subnet.rds-subnet-2.id]

  tags = {
    Name = "sqlserver-db-subnet-group"
  }
}

#######################################################################################
# Security 
#######################################################################################

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "allow rds access"
  vpc_id      = aws_vpc.rds-vpc.id

  ingress {
    description = "allow rds access"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["X.X.X.X/32"]
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

#################################################################################
# RDS
#################################################################################

resource "aws_db_instance" "rds-sqlserver" {
  allocated_storage      = 20
  apply_immediately      = true
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  engine                 = "sqlserver-ex"
  engine_version         = "15.00.4153.1.v1"
  identifier             = "test-rds-sqlserver"
  instance_class         = "db.t3.large"
  username               = "rdsuser"
  password               = var.password
  port                   = 1433
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
}