provider "aws" {
  profile = data.terraform_remote_state.basesg.outputs.aws_profile #var.aws_profile
  region  = data.terraform_remote_state.basesg.outputs.aws_region  # var.aws_region
}
provider "cloudflare" {
  api_token = data.vault_generic_secret.cloudflare-info.data["apitoken"]
}
provider "vault" {
  address            = "http://husserv.hjem.hald.id.au:8200"
  add_address_to_env = true
  namespace          = "secret"
}