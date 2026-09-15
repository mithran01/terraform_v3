resource "aws_instance" "dns" {
  ami           = data.aws_ami.rocky_linux.id
  instance_type = "t3.micro"

  subnet_id = data.aws_subnet.subnet_us_east_1a.id

  private_ip = cidrhost(
    data.aws_subnet.subnet_us_east_1a.cidr_block,
    var.dns_host_number
  )

  key_name = data.aws_key_pair.existing_key.key_name

  vpc_security_group_ids = [
    data.aws_security_group.default.id
  ]

  tags = {
    Name       = "dns-Server"
    Managed_by = "Terraform-user"
  }
}
