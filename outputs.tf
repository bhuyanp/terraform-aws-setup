output "region" {
  value = var.region
}
output "application-name" {
  value = var.app-name
}

output "publicip-of-ec2-inside-pub-subnet" {
  value = aws_instance.tfpoc-pub.public_ip
}

output "internalip-of-ec2-inside-pvt-subnet" {
  value = aws_instance.tfpoc-pvt.private_ip
}
