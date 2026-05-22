output "ansible_plane_ips" {
  value = aws_instance.Ansible_plane[*].private_ip
}
