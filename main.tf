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

# Reference to app tier module
module "app_tier" {
  source = "./modules/app_tier"
  vpc_id = aws_vpc.mainvpc.id
  name = var.name
  my_ip = var.my_ip
  internet_gateway_id = aws_internet_gateway.gw.id
  db_private_ip = aws_instance.DB.private_ip
  ami_app = var.ami_app
  # ssh_key_var = var.ssh_key_var
}

##------------------------------##

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
    # cidr_blocks = ["41.0.1.0/24"]
    security_groups = [module.app_tier.security_group_id]
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

resource "aws_network_acl" "naclprivate" {
  vpc_id = aws_vpc.mainvpc.id
  
  ingress {
    protocol    = "tcp"
    rule_no     = 100
    action      = "allow"
    cidr_block  = module.app_tier.subpublic_cidr_block
    from_port   = 27017
    to_port     = 27017
  }
  egress {
    protocol    = "tcp"
    rule_no     = 120
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 1024
    to_port     = 65535
  }

  subnet_ids = [aws_subnet.subprivate.id]

  tags = {

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



