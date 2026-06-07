# Internet Gateway for public subnet inbound/egress.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-igw"
  }
}

# Fixed egress IP for outbound traffic to whitelisted partner systems.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.name}-nat-eip"
  }
}

# Single NAT Gateway keeps the demo cheap; production would use one per AZ.
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${local.name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}
