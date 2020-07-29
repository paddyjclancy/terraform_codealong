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
  db_private_ip = module.db_tier.db_private_ip
  ami_app = var.ami_app
  # ssh_key_var = var.ssh_key_var
}

##------------------------------##

#### Private

module "db_tier" {
  source = "./modules/db_tier"
  vpc_id = aws_vpc.mainvpc.id
  name = var.name
  subpublic_cidr_block = module.app_tier.subpublic_cidr_block
  app_sg_id = module.app_tier.app_sg_id
  ami_db = var.ami_db
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



