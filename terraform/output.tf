
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.instance_public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2.instance_public_dns
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.ec2.instance_private_ip
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${module.ec2.instance_public_ip}"
}
