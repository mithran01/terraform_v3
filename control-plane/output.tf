output "control_plane_ips" {
  value = aws_instance.control_plane[*].private_ip
}
