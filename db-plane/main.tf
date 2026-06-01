# -----------------------------------------------------------------------------
# AUTO SCALING GROUP
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "db_plane_asg" {

  name = "db-plane-asg"

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  vpc_zone_identifier = [
    data.aws_subnet.subnet_us_east_1c.id
  ]

  health_check_type = "EC2"

  launch_template {

    id      = aws_launch_template.db_plane.id
    version = "$Latest"
  }

  # ---------------------------------------------------------------------------
  # CLUSTER AUTOSCALER TAGS
  # ---------------------------------------------------------------------------

  tag {
    key                 = "Name"
    value               = "db-plane"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "db-plane"
    propagate_at_launch = true
  }


  lifecycle {
    create_before_destroy = true
  }
}
