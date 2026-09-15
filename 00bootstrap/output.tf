output "subnet_1a_cidr" {
  value = data.aws_subnet.subnet_us_east_1a.cidr_block
}

output "subnet_1b_cidr" {
  value = data.aws_subnet.subnet_us_east_1b.cidr_block
}
