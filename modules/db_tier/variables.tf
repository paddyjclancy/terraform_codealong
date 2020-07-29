variable "vpc_id" {
  description = "The VPC we want the instance to launch within"  
}

variable "name" {
  description = "Root base on naming for convention"
}

variable "subpublic_cidr_block" {
  description = "IP for public subnet"
}

variable "app_sg_id" {
  description = "Security group of app"
}

variable "ami_db" {
  description = "ami for db"
}