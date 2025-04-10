resource "aws_vpc" "airbyte_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "airbyte-vpc"
  }
}

resource "aws_subnet" "airbyte_subnet" {
  vpc_id            = aws_vpc.airbyte_vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "airbyte-subnet"
  }
}

resource "aws_security_group" "airbyte_sg" {
  vpc_id = aws_vpc.airbyte_vpc.id
  tags = {
    Name = "airbyte-sg"
  }
}

resource "aws_instance" "airbyte_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.airbyte_subnet.id
  security_groups = [aws_security_group.airbyte_sg.name]

  tags = {
    Name = "airbyte-instance"
  }
}

output "airbyte_instance_id" {
  value = aws_instance.airbyte_instance.id
}

output "airbyte_instance_public_ip" {
  value = aws_instance.airbyte_instance.public_ip
}