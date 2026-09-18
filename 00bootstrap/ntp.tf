resource "aws_instance" "ntp" {
  count         = 0
  ami           = data.aws_ami.rocky_linux.id
  instance_type = "t3.micro"

  subnet_id = data.aws_subnet.subnet_us_east_1a.id

  private_ip = cidrhost(
    data.aws_subnet.subnet_us_east_1a.cidr_block,
    var.ntp_host_number
  )

  key_name = data.aws_key_pair.existing_key.key_name

  vpc_security_group_ids = [
    data.aws_security_group.default.id
  ]

  #user_data = file("${path.module}/ntp-userdata.sh")
  #user_data_replace_on_change = true

  #metadata_options {
  #  http_tokens = "required"
  #}

  tags = {
    Name        = "ntp01"
    Role        = "ntp"
    Environment = "lab"
    Managed_by  = "Terraform-user"
  }
}
