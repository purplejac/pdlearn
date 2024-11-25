terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    external = {
      source  = "hashicorp/external"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
    vault = {
      source  = "hashicorp/vault"
    }
  }
}
