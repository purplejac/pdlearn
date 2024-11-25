data "external" "my-ip" {
  program = ["/usr/bin/curl", "--connect-timeout", "180", "https://api64.ipify.org?format=json"]
}

#
# Retrieve information about other resources in the buildset with the base security group and cloudflare secret
#
data "terraform_remote_state" "basesg" {
  backend = "local"

  config = {
    path = pathexpand("~/tofu/tofu-basesg.tfstate")
  }
}
data "vault_generic_secret" "cloudflare-info" {
  path = "secret/cloudflare"
}
