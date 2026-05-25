terraform {
  backend "s3" {
    bucket = "openemr-kubeadm-tfstate"
    key    = "data-plane/terraform.tfstate"
    region = "us-east-1"
  }
}
