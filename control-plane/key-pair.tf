resource "aws_key_pair" "demov2" {
  key_name   = "demov2"
  public_key = var.control_plane_key
}
