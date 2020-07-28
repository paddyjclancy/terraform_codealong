provider "aws" {
  region = "eu-west-1"
}

# Creating a vpc
resource "aws_vpc" "mainvpc" {
  cidr_block = "41.0.0.0/16"
  tags = {

    Name = "${var.name}vpc"
  }
}

# Create an igw
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mainvpc.id
  tags = {
    Name = "${var.name}igw"
  }
}

# Create public sub
resource "aws_subnet" "subpublic" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "41.0.1.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}public.sub"
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
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "port 3000 from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}SG.App"
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
    protocol    = "tcp"
    rule_no     = 120
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 1024
    to_port     = 65535
  }

  ingress {
    protocol    = "tcp"
    rule_no     = 120
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 1024
    to_port     = 65535
  }

  ingress {
    rule_no     = 130
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    action      = "allow"
    cidr_block = "${var.my_ip}"
  }  

  egress {
    rule_no     = 130
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    action      = "allow"
    cidr_block = "${var.my_ip}"
  }  

  subnet_ids = [aws_subnet.subpublic.id]

  tags = {
    Name = "${var.name}NACL.public"
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
    Name = "${var.name}route.public"
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
  vars = {
    db_host = "${aws_instance.DB.private_ip}"
  }
}


# Creating an ec2 instance IMAGE with our app
resource "aws_instance" "Web" {
  ami                         = var.ami-app
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subpublic.id
  vpc_security_group_ids      = [aws_security_group.sgapp.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.initapp.rendered
  tags                        = {
    Name = "${var.name}app"
  }
}

#### Private

# Create public sub
resource "aws_subnet" "subprivate" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "41.0.2.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "${var.name}private.sub"
  }
}

# Creating security group for db
resource "aws_security_group" "sgdb" {
  name        = "db-sg"
  description = "Allow http and https traffic"
  vpc_id      = aws_vpc.mainvpc.id

  ingress {
    description = "Mongodb connection"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["41.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}SG.DB"
  }
}

# Create EC2 instance - private
resource "aws_instance" "DB" {
  ami                         = var.ami-db
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subprivate.id
  vpc_security_group_ids      = [aws_security_group.sgdb.id]
  associate_public_ip_address = true
  # user_data                   = data.template_file.initdb.rendered
  tags                        = {
    Name = "${var.name}db"
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



