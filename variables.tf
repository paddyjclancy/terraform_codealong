variable "vpc_id" {
  type = string
  default= "vpc-08039043ffb902e94"
}

variable "name" {
  type = string
  default= "Eng57.PC."
}

variable "ami-app" {
  default = "ami-00b48f09c568b0014"
}

variable "ami-db" {
  default = "ami-03b13f993274ce14a"
}