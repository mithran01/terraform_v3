variable "aws_region" {
  type = string
}
variable "desired_capacity" {
  type    = number
  default = 3
}

variable "min_size" {
  type    = number
  default = 3
}

variable "max_size" {
  type    = number
  default = 3
}
