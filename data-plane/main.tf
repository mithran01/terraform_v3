# -----------------------------------------------------------------------------
# AUTO SCALING GROUP
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "data_plane_asg" {

  name = "data-plane-asg"

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  vpc_zone_identifier = [
    data.aws_subnet.subnet_us_east_1a.id,
    data.aws_subnet.subnet_us_east_1b.id
  ]

  health_check_type = "EC2"

  launch_template {

    id      = aws_launch_template.data_plane.id
    version = "$Latest"
  }

  # ---------------------------------------------------------------------------
  # CLUSTER AUTOSCALER TAGS
  # ---------------------------------------------------------------------------

  tag {
    key                 = "Name"
    value               = "data-plane-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "data-plane"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/openemr-prod"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
