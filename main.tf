# create VPC
resource "aws_vpc" "cpd_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "cpd_vpc"
  }
}
# create pub subnet 1
resource "aws_subnet" "cpd_public_subnet_1" {
  vpc_id            = aws_vpc.cpd_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "cpd_public_subnet_1"
  }
}

# create pub subnet 2
resource "aws_subnet" "cpd_public_subnet_2" {
  vpc_id            = aws_vpc.cpd_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "cpd_public_subnet_2"
  }
}

# create prv subnet 1
resource "aws_subnet" "cpd_private_subnet_1" {
  vpc_id            = aws_vpc.cpd_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "cpd_private_subnet_1"
  }
}   

# create prv subnet 2
resource "aws_subnet" "cpd_private_subnet_2" {
  vpc_id            = aws_vpc.cpd_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "cpd_private_subnet_2"
  }
}   
# create an IGW
resource "aws_internet_gateway" "cpd_gw" {
  vpc_id = aws_vpc.cpd_vpc.id

  tags = {
    Name = "cpd_gw"
  }
}
# create a public route table
resource "aws_route_table" "cpd_public_subnet_RT" {
  vpc_id = aws_vpc.cpd_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cpd_gw.id
  }
  tags = {
    Name = "cpd_public_subnet_RT"
  }
}
# assiociation of route table to public subnet 1
resource "aws_route_table_association" "cpd_Public_RT_ass" {
  subnet_id      = aws_subnet.cpd_public_subnet_1.id
  route_table_id = aws_route_table.cpd_public_subnet_RT.id
}

# assiociation of route table to public subnet 2
resource "aws_route_table_association" "cpd_Public_RT_ass_2" {
  subnet_id      = aws_subnet.cpd_public_subnet_2.id
  route_table_id = aws_route_table.cpd_public_subnet_RT.id
}

# Allocate Elastic IP Address (EIP )
# terraform aws allocate elastic ip
resource "aws_eip" "eip-for-nat-gateway" {
  vpc    = true

  tags   = {
    Name = "EIP_1"
  }
}

# Create Nat Gateway  in Public Subnet 1
# terraform create aws nat gateway
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.eip-for-nat-gateway.id
  subnet_id     = aws_subnet.cpd_public_subnet_1.id

  tags   = {
    Name = "Nat_Gateway_Public_Subnet_1"
  }
}

# Create Private Route Table  and Add Route Through Nat Gateway 
# terraform aws create route table
resource "aws_route_table" "cpd_private-route-table" {
  vpc_id            = aws_vpc.cpd_vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat-gateway.id
  }

  tags   = {
    Name = "Private_Route_Table_1"
  }
}

# Associate Private Subnet 1 with "Private Route Table "
# terraform aws associate subnet with route table
resource "aws_route_table_association" "private-subnet-1-route-table-association" {
  subnet_id         = aws_subnet.cpd_private_subnet_1.id
  route_table_id    = aws_route_table.cpd_private-route-table.id
}

# Associate Private Subnet 2 with "Private Route Table "
# terraform aws associate subnet with route table
resource "aws_route_table_association" "private-subnet-2-route-table-association" {
  subnet_id         = aws_subnet.cpd_private_subnet_2.id
  route_table_id    = aws_route_table.cpd_private-route-table.id
}

# create security group
resource "aws_security_group" "cpd-frontend-security-group" {
  name   = "cpd-frontend-security-group"
  vpc_id = aws_vpc.cpd_vpc.id
  ingress {
    description = "http port access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh port access"
    from_port   = 22
    to_port     = 22
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
    Name = "cpd_frontend_security_group"
  }
}

# create database security group
resource "aws_security_group" "cpd_backend-security-group" {
  name   = "cpd-backend-security-group"
  vpc_id = aws_vpc.cpd_vpc.id
  ingress {
    description = "mysql port access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24","10.0.2.0/24"]
  }
  ingress {
    description = "ssh port access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24","10.0.2.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "cpd_backend_security_group"
  }
}
# creating of s3 bucket
resource "aws_s3_bucket" "cpd-s3mediab" {
  bucket = "cpd-s3mediab"

  tags = {
    Name        = "cpd-s3mediab"

  }
}

# bucket policy
resource "aws_s3_bucket_policy" "cpd-s3mediabpolicy" {
  bucket = aws_s3_bucket.cpd-s3mediab.id
  policy = jsonencode({
  
   Statement = [
      {
        Action = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
        Effect = "Allow"
        Sid    = "PublicReadGetObject"
        Principal = {
          AWS = "*"
        }
        Resource = "arn:aws:s3:::cpd-s3mediab/*"
      }
    ]
  })

 
}

# s3 code bucket
resource "aws_s3_bucket" "cpd-s3codeb" {
  bucket = "cpd-s3codeb"

  tags = {
    Name        = "cpd-s3codeb"

  }
}


# create iam profile for Ec2
resource "aws_iam_instance_profile" "cpd-s3bprofile" {
  name = "cpd-s3bprofile"
  role = aws_iam_role.cpd-s3biam.name
}

# create iam role
resource "aws_iam_role" "cpd-s3biam" {
  name = "cpd-s3biam"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# create iam policy attachment
resource "aws_iam_role_policy_attachment" "cpd-s3b-policy-attachment" {
  role       = aws_iam_role.cpd-s3biam.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


#Create DB subnet groups
resource "aws_db_subnet_group" "cpd_db_sb_group" {
  name        = "cpd_mysyq_db"
  subnet_ids  = [aws_subnet.cpd_private_subnet_1.id, aws_subnet.cpd_private_subnet_2.id]
  description = "Subnets for Captone DB Instance"

  tags = {
    Name = "cpd-sub-grp"
  }
}


resource "aws_db_instance" "cpd-db" {
  allocated_storage      = 10
  max_allocated_storage  = 50
  db_name                = "cpd_db"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = var.username
  password               = var.passwd
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.cpd_db_sb_group.id
  vpc_security_group_ids = [aws_security_group.cpd_backend-security-group.id]
  multi_az               = true
  skip_final_snapshot    = true
}
