terraform {
  backend "s3" {
    bucket = "openemr-kubeadm-tfstate"
    key    = "control-plane/terraform.tfstate"
    region = "us-east-1"
  }
}
