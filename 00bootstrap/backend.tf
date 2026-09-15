terraform {
  backend "s3" {
    bucket = "openemr-kubeadm-tfstate"
    key    = "00bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}
