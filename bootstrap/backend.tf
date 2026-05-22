terraform {
  backend "s3" {
    bucket = "openemr-kubeadm-tfstate"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}
