resource "aws_launch_template" "data_plane" {
  name_prefix   = "data-plane-"
  image_id      = data.aws_ami.rocky_linux.id
  instance_type = "t3.small"
  key_name      = data.aws_key_pair.existing_key_2.key_name

  vpc_security_group_ids = [data.aws_security_group.default.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.data_plane_profile.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
  update_default_version = true

  #ROOT VOLUME CONFIG (IMPORTANT PART)
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
      encrypted             = false
    }
  }
  # install dependencies
  # configure containerd
  # disable swap
  # configure sysctl

  user_data = base64encode(templatefile("${path.module}/worker.sh.tpl", {
    aws_region = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      #Name = "swarm-worker"
      Role                                 = "data-plane"
      Name                                 = "data-plane-"
      Managed_by                           = "Terraform-user"
      "kubernetes.io/cluster/openemr-prod" = "owned"
    }
  }
}
