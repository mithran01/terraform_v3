resource "aws_instance" "ansible_plane" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.subnet_us_east_1a.id
  key_name                    = data.aws_key_pair.existing_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.ansible_profile.name
  associate_public_ip_address = true
  vpc_security_group_ids      = ["sg-0a77e32b49bdfe70e"]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ansible_plane_key
    host        = aws_instance.ansible_plane.public_ip
  }


  provisioner "file" {
    source      = "../demov2.pem"             # this file located from working directory
    destination = "/home/ec2-user/demov2.pem" #
  }

  provisioner "file" {
    source      = "ansible.sh"
    destination = "/home/ec2-user/ansible.sh" # ...to the EC2 master node
  }

  # Optional: Fix permissions for the copied key on the remote host
  provisioner "remote-exec" {
    inline = ["chmod 400 /home/ec2-user/demov2.pem"]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/ansible.sh",
      "chown ec2-user:ec2-user /home/ec2-user/ansible.sh"
    ]
  }

  tags = {
    Name       = "Ansible-Server"
    Managed_by = "Terraform-user"
  }
}
