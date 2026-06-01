terraform {
  backend "s3" {
    bucket = "openemr-kubeadm-tfstate"
    key    = "db-plane/terraform.tfstate"
    region = "us-east-1"
  }
}
