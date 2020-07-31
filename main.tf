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

# Load balancer - sg
resource "aws_lb" "lb_test" {
  name               = "testLB" 
  internal           = false
  load_balancer_type = "network"
  security_groups    = ["${module.app_tier.app_sg_id}"]
}

## Load balancer - listener
resource "aws_lb_listener" "listener_test" {
  load_balancer_arn  = aws_lb.lb_test.arn
  port               = 443
  protocol           = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG_test.arn
  }
}

## Load balancer - target group
resource "aws_lb_target_group" "TG_test" { 
  name            = "testTG"
  port            = 80
  protocol        = "HTTP"
  vpc_id          = aws_vpc.mainvpc.id
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
}

# Reference to db tier module
module "db_tier" {
  source = "./modules/db_tier"
  vpc_id = aws_vpc.mainvpc.id
  name = var.name
  subpublic_cidr_block = module.app_tier.subpublic_cidr_block
  app_sg_id = module.app_tier.app_sg_id
  ami_db = var.ami_db
}

