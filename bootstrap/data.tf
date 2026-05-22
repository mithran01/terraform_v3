# vpc check
data "aws_vpc" "default" {
  default = true
}
# subnet 1
data "aws_subnet" "subnet_us_east_1a" {
  id = "subnet-0b4c028473d106e9e"
}
# subnet 2
data "aws_subnet" "subnet_us_east_1b" {
  id = "subnet-0dc53fd2b335c29f6"
}
#default security group
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}
# amazon linux ami
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}
# rocky linux ami
data "aws_ami" "rocky_linux" {
  most_recent = true

  owners = ["792107900819"]

  filter {
    name   = "name"
    values = ["Rocky-9-EC2-Base-*x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# default keypair check
data "aws_key_pair" "existing_key" {
  key_name = "demov1"
}
