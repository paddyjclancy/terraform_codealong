output "app_sg_id" {
  description = "ID of app SG"
  value = aws_security_group.sgapp.id
}

output "subpublic_cidr_block" {
  description = "cidr_block of public subnet"
  value = aws_subnet.subpublic.cidr_block
}