

# Create private sub
resource "aws_subnet" "subprivate" {
  vpc_id     = var.vpc_id
  cidr_block = "41.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "${var.name}private.sub"
  }
}

# Create private security group
resource "aws_security_group" "sgdb" {
  name        = "db-sg"
  description = "Allow http and https traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Mongodb connection"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    # cidr_blocks = ["41.0.1.0/24"]
    security_groups = [var.app_sg_id]
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

# Create private NACL
resource "aws_network_acl" "naclprivate" {
  vpc_id = var.vpc_id
  
  ingress {
    protocol    = "tcp"
    rule_no     = 100
    action      = "allow"
    cidr_block  = var.subpublic_cidr_block
    from_port   = 27017
    to_port     = 27017
  }
  egress {
    protocol    = "tcp"
    rule_no     = 120
    action      = "allow"
    cidr_block  = var.subpublic_cidr_block
    from_port   = 1024
    to_port     = 65535
  }

  subnet_ids = [aws_subnet.subprivate.id]

  tags = {

  }
}

# Create EC2 db instance
resource "aws_instance" "DB" {
  ami                         = var.ami_db
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subprivate.id
  vpc_security_group_ids      = [aws_security_group.sgdb.id]
  associate_public_ip_address = true
  # user_data                   = data.template_file.initdb.rendered
  tags                        = {
    Name = "${var.name}db"
  }
}
