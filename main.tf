provider "aws" {
  region = "eu-west-1"
}

# Creating a vpc
resource "aws_vpc" "mainvpc" {
  cidr_block = "13.0.0.0/16"
  tags = {

    Name = "Eng57.fp.tf.vpc"
  }
}

# Create an igw
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mainvpc.id
  tags = {
    Name = "${var.name} igw"
  }
}

# Create public sub
resource "aws_subnet" "subpublic" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "13.0.1.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name} sub.public"
  }
}

# Creating security group for webapp
resource "aws_security_group" "sgapp" {
  name        = "app-sg"
  description = "Allow http and https traffic"
  vpc_id      = aws_vpc.mainvpc.id

  ingress {
    description = "https from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "httpx from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "httpx from VPC"
    from_port   = 3000
    to_port     = 3000
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
    Name = "Eng57.fp.sg.app"
  }
}

# Creating NACls for public sub
resource "aws_network_acl" "naclpublic" {
  vpc_id = aws_vpc.mainvpc.id

  # traffic on por 80 allow
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # traffic on por EPHEMERAL PORTS allow

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  subnet_ids = [aws_subnet.subpublic.id]

  tags = {
    Name = "Eng57.fp.nacls.public"
  }
}

# Creating a route table
resource "aws_route_table" "routepublic" {
  vpc_id = aws_vpc.mainvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Eng57.fp.route.public"
  }
}

# Route table associations
resource "aws_route_table_association" "routeapp" {
  subnet_id = aws_subnet.subpublic.id
  route_table_id = aws_route_table.routepublic.id
}

# load init script to be used
data "template_file" "initapp" {
  template = file("./scripts/app/init.sh.tpl")
  # vars = {
  #   consul_address = "${aws_instance.consul.private_ip}"
  # }
}


# Creating an ec2 instance IMAGE with our app
resource "aws_instance" "Web" {
  ami           = "ami-00b48f09c568b0014"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subpublic.id
  vpc_security_group_ids = [aws_security_group.sgapp.id]
  associate_public_ip_address = true
  user_data = data.template_file.initapp.rendered
  tags = {
    Name = "Eng57.filipe.paiva.tf.app"
  }
}





# Creating an example ec2 instance
# resource "aws_instance" "Web" {
#   ami           = "ami-089cc16f7f08c4457"
#   instance_type = "t2.micro"
#   associate_public_ip_address = true
#   tags = {
#     Name = "Eng57.filipe.paiva.tf.app"
#   }
# }

# resource "aws_instance" "Bastion" {
#   ami           = "ami-089cc16f7f08c4457"
#   instance_type = "t2.micro"
#   associate_public_ip_address = true
#   tags = {
#     Name = "Eng57.filipe.paiva.tf.bastion"
#   }
# }

# create vpc
# give it the tag Name Eng57.your.name.vpc.tf

# add a itg
# add some routes
# add some subnets
# add some NACLs
# add



