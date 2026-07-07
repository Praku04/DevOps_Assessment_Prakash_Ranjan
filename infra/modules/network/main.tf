resource "aws_vpc" "insurance_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "insurance_internet_gateway" {
  vpc_id = aws_vpc.insurance_vpc.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_subnet" "insurance_public_subnet_1" {
  vpc_id                  = aws_vpc.insurance_vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-1"
    Tier = "public"
  }
}

resource "aws_subnet" "insurance_public_subnet_2" {
  vpc_id                  = aws_vpc.insurance_vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-2"
    Tier = "public"
  }
}

resource "aws_subnet" "insurance_private_subnet_1" {
  vpc_id            = aws_vpc.insurance_vpc.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${var.name}-private-subnet-1"
    Tier = "private"
  }
}

resource "aws_subnet" "insurance_private_subnet_2" {
  vpc_id            = aws_vpc.insurance_vpc.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "${var.name}-private-subnet-2"
    Tier = "private"
  }
}

resource "aws_eip" "insurance_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip"
  }
}

resource "aws_nat_gateway" "insurance_nat_gateway" {
  allocation_id = aws_eip.insurance_nat_eip.id
  subnet_id     = aws_subnet.insurance_public_subnet_1.id

  tags = {
    Name = "${var.name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.insurance_internet_gateway]
}

resource "aws_route_table" "insurance_public_route_table" {
  vpc_id = aws_vpc.insurance_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.insurance_internet_gateway.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route_table_association" "insurance_public_route_table_association_1" {
  subnet_id      = aws_subnet.insurance_public_subnet_1.id
  route_table_id = aws_route_table.insurance_public_route_table.id
}

resource "aws_route_table_association" "insurance_public_route_table_association_2" {
  subnet_id      = aws_subnet.insurance_public_subnet_2.id
  route_table_id = aws_route_table.insurance_public_route_table.id
}

resource "aws_route_table" "insurance_private_route_table" {
  vpc_id = aws_vpc.insurance_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.insurance_nat_gateway.id
  }

  tags = {
    Name = "${var.name}-private-rt"
  }
}

resource "aws_route_table_association" "insurance_private_route_table_association_1" {
  subnet_id      = aws_subnet.insurance_private_subnet_1.id
  route_table_id = aws_route_table.insurance_private_route_table.id
}

resource "aws_route_table_association" "insurance_private_route_table_association_2" {
  subnet_id      = aws_subnet.insurance_private_subnet_2.id
  route_table_id = aws_route_table.insurance_private_route_table.id
}
