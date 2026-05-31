resource "aws_instance" "control_plane" {
  count                       = 1
  ami                         = data.aws_ami.rocky_linux.id
  instance_type               = "t3.medium"
  subnet_id                   = data.aws_subnet.subnet_us_east_1a.id
  key_name                    = aws_key_pair.demov2.key_name
  iam_instance_profile        = aws_iam_instance_profile.kubeadm_profile_01.name
  associate_public_ip_address = true
  vpc_security_group_ids      = ["sg-0a77e32b49bdfe70e"]



  tags = {
    Name                                 = "control-plane-${count.index}"
    Role                                 = "control-plane"
    Managed_by                           = "Terraform-user"
    "kubernetes.io/cluster/openemr-prod" = "owned"
  }
}


resource "local_file" "control_plane_ips" {
  content  = join("\n", aws_instance.control_plane[*].private_ip)
  filename = "control-plane-ips.txt"
}

resource "null_resource" "copy_ips" {
  provisioner "file" {
    source      = "control-plane-ips.txt"
    destination = "/home/ec2-user/control-plane-ips.txt"
  }


  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ansible_plane_key
    host        = aws_instance.ansible_plane.public_ip
  }

  depends_on = [
    aws_instance.ansible_plane,
    local_file.control_plane_ips
  ]
}

resource "null_resource" "run_ansible_script" {

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/ansible.sh",
      "/home/ec2-user/ansible.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ansible_plane_key
    host        = aws_instance.ansible_plane.public_ip
  }

  depends_on = [
    aws_instance.ansible_plane,
    aws_instance.control_plane,
    null_resource.copy_ips
  ]
}
