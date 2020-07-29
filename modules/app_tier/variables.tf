variable "vpc_id" {
  description = "The VPC we want the instance to launch within"  
}

variable "name" {
  description = "Root base on naming for convention"
}

variable "my_ip" {
  description = "Local IP to create secure port 22 connection with resources"
}

variable "internet_gateway_id" {
  description = "IP of IGW"
}

variable "db_private_ip" {
  description = "Private IP of DB"
}

variable "ami_app" {
  description = "ami for app"
}