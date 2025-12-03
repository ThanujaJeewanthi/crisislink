provider "aws" {  
  region = "us-east-1"  
}  

resource "aws_vpc" "crisislink_vpc" {  
  cidr_block = "10.0.0.0/16"  
  tags = { Name = "CrisisLink VPC" }  
}  

resource "aws_subnet" "public_subnet" {  
  vpc_id     = aws_vpc.crisislink_vpc.id  
  cidr_block = "10.0.1.0/24"  
  availability_zone = "us-east-1a"  
  map_public_ip_on_launch = true  
  tags = { Name = "Public Subnet" }  
}  

resource "aws_subnet" "private_subnet" {  
  vpc_id     = aws_vpc.crisislink_vpc.id  
  cidr_block = "10.0.2.0/24"  
  availability_zone = "us-east-1a"  
  tags = { Name = "Private Subnet" }  
}

resource "aws_subnet" "private_subnet_2" {  
  vpc_id     = aws_vpc.crisislink_vpc.id  
  cidr_block = "10.0.3.0/24"  
  availability_zone = "us-east-1b"  
  tags = { Name = "Private Subnet 2" }  
}

resource "aws_internet_gateway" "igw" {  
  vpc_id = aws_vpc.crisislink_vpc.id  
  tags = { Name = "CrisisLink IGW" }  
}  

resource "aws_route_table" "public_rt" {  
  vpc_id = aws_vpc.crisislink_vpc.id  
  route {  
    cidr_block = "0.0.0.0/0"  
    gateway_id = aws_internet_gateway.igw.id  
  }  
  tags = { Name = "Public Route Table" }  
}  

resource "aws_route_table_association" "public_assoc" {  
  subnet_id      = aws_subnet.public_subnet.id  
  route_table_id = aws_route_table.public_rt.id  
}  

resource "random_string" "bucket_suffix" {  
  length  = 8  
  special = false  
  upper   = false  
}  

resource "aws_s3_bucket" "frontend_bucket" {  
  bucket = "crisislink-frontend-${random_string.bucket_suffix.result}"  
  tags = { Name = "CrisisLink Frontend" }  
} 

resource "aws_s3_bucket_public_access_block" "block_public" {  
  bucket = aws_s3_bucket.frontend_bucket.id  
  block_public_acls       = true  
  block_public_policy     = true  
  ignore_public_acls      = true  
  restrict_public_buckets = true  
}

resource "aws_dynamodb_table" "help_requests" {  
  name           = "HelpRequests"  
  billing_mode   = "PAY_PER_REQUEST"  
  hash_key       = "RequestID"  
  attribute {  
    name = "RequestID"  
    type = "S"  
  }  
  tags = { Name = "CrisisLink DynamoDB" }  
}  

resource "aws_db_subnet_group" "rds_group" {  
  name       = "crisislink-rds-group"  
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_2.id]  
}

resource "aws_security_group" "rds_sg" {  
  vpc_id = aws_vpc.crisislink_vpc.id  
  ingress {  
    from_port   = 3306  
    to_port     = 3306  
    protocol    = "tcp"  
    cidr_blocks = ["10.0.0.0/16"]  
  }  
  egress {  
    from_port   = 0  
    to_port     = 0  
    protocol    = "-1"  
    cidr_blocks = ["0.0.0.0/0"]  
  }  
}  

resource "aws_db_instance" "user_db" {  
  identifier           = "crisislink-db"  
  engine               = "mysql"  
  instance_class       = "db.t3.micro"  
  allocated_storage    = 20  
  db_name              = "userdb"  
  username             = "admin"  
  password             = "YourStrongPassword123!"  
  db_subnet_group_name = aws_db_subnet_group.rds_group.name  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  
  skip_final_snapshot  = true  
  publicly_accessible  = false  
  storage_encrypted    = true  
  tags = { Name = "CrisisLink RDS" }  
}  
