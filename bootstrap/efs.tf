resource "aws_security_group" "efs_sg" {
  name        = "efs-security-group"
  description = "Allow NFS traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"

    cidr_blocks = [
      "172.31.0.0/16"
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name       = "efs-security-group"
    Managed_by = "Terraform-user"
  }
}

resource "aws_efs_file_system" "main" {
  creation_token = "k8s-efs"

  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name       = "k8s-efs"
    Managed_by = "Terraform-user"
  }
}

resource "aws_efs_mount_target" "mount_1a" {
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = data.aws_subnet.subnet_us_east_1a.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "mount_1b" {
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = data.aws_subnet.subnet_us_east_1b.id
  security_groups = [aws_security_group.efs_sg.id]
}

output "efs_id" {
  value = aws_efs_file_system.main.id
}
