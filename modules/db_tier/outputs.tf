output "db_private_ip" {
  description = "IP of db instance"
  value = aws_instance.DB.private_ip
}