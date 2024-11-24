terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #      version = "~> 4.16"
    }
    external = {
      source = "hashicorp/external"
      #      version = "~> 2.2.2"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      #version = "~> 4.36.0"
    }
    vault = {
      source = "hashicorp/vault"
      #version = "3.6.0"
    }
  }
  backend "local" {
    path = pathexpand("~/tofu/tofu-basesg.tfstate")
  }
}
