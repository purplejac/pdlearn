#
# Setup terraform required_providers and configure the backend to export tfstate information
#
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    external = {
      source = "hashicorp/external"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      #version = "~> 4.36.0"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
  backend "local" {
    path = pathexpand("~/tofu/tofu-basesg.tfstate")
  }
}
