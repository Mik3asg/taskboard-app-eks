// Fetch available AZs in the region dynamically — avoids hardcoding eu-west-2a/b/c
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr

  // Required for EKS: enables DNS resolution and hostname assignment for nodes
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
    Project = var.project_name
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    // Tells AWS Load Balancer Controller to use these subnets for internet-facing ALBs/NLBs
    "kubernetes.io/role/elb"                    = "1"
    // Registers this subnet with the EKS cluster; "shared" allows use by multiple clusters
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Project                                     = var.project_name
    Environment                                 = var.environment
  }
}

resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    // Tells AWS Load Balancer Controller to use these subnets for internal ALBs/NLBs
    "kubernetes.io/role/internal-elb"           = "1"
    // Registers this subnet with the EKS cluster
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Project                                     = var.project_name
    Environment                                 = var.environment
  }
}

// Internet Gateway — gives public subnets a route to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

// Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-eip"
    Project     = var.project_name
    Environment = var.environment
  }
}

// NAT Gateway — allows private subnet nodes to reach the internet (e.g. pull images)
// Placed in first public subnet only
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

// Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Project                                     = var.project_name
    Environment                                 = var.environment
  }
}

// Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
    Project                                     = var.project_name
    Environment                                 = var.environment
  }
}
// Associate each public subnet with the public route table
resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

// Associate each private subnet with the private route table
resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}