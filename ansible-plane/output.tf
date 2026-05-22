output "ansible_plane_ips" {
  value = aws_instance.ansible_plane[*].private_ip
}
