output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "control_plane_public_ip" {
  description = "Public IP of the control plane node"
  value       = aws_instance.control_plane.public_ip
}

output "control_plane_private_ip" {
  description = "Private IP of the control plane node"
  value       = aws_instance.control_plane.private_ip
}

output "worker_nodes_public_ips" {
  description = "Public IPs of the worker nodes"
  value       = aws_instance.workers[*].public_ip
}

output "worker_nodes_private_ips" {
  description = "Private IPs of the worker nodes"
  value       = aws_instance.workers[*].private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "control_plane_security_group_id" {
  description = "ID of the control plane security group"
  value       = aws_security_group.control_plane.id
}

output "workers_security_group_id" {
  description = "ID of the workers security group"
  value       = aws_security_group.workers.id
}

output "ssh_command" {
  description = "SSH command to connect to control plane"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.control_plane.public_ip}"
}
