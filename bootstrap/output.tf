output "ansible_plane_ips" {
  value = aws_instance.ansible_plane[*].private_ip
}

output "control_plane_ips" {
  value = aws_instance.control_plane[*].private_ip
}

output "ansible_plane_instance_id" {
  value = aws_instance.ansible_plane[*].id
}
