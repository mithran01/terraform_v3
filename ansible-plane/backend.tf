terraform {
  backend "s3" {
    bucket = "openemr-kubeadm-tfstate"
    key    = "ansible-plane/terraform.tfstate"
    region = "us-east-1"
  }
}
