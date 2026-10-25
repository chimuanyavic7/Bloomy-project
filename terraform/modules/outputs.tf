
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.public_ec2.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.public_ec2.public_dns
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.public_ec2.private_ip
}
