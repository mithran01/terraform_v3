resource "aws_key_pair" "control_plane_key_creation" {
  key_name   = "demov2"
  public_key = var.control_plane_key
}
