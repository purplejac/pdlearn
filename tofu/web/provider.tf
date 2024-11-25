#
# For a better cross-code experience, setup and use the profile/region configured
# for the base security group. This one was chosen as it would generally be the one
# resource that should always be available. Allows for a simple standardised override
# for the config options.
#
# Then configure cloudflare, by retrieving a token from vault, and setup the vaul provider.
#
provider "aws" {
  profile = data.terraform_remote_state.basesg.outputs.aws_profile
  region  = data.terraform_remote_state.basesg.outputs.aws_region
}
provider "cloudflare" {
  api_token = data.vault_generic_secret.cloudflare-info.data["apitoken"]
}
provider "vault" {
  address            = "http://husserv.hjem.hald.id.au:8200"
  add_address_to_env = true
  namespace          = "secret"
}
