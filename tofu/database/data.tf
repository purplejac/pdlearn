#
# Check the local IP address and make it available as a data resource for rule creation
#
data "external" "my-ip" {
  program = ["/usr/bin/curl", "--connect-timeout", "180", "https://api64.ipify.org?format=json"]
}
#
# Retrieve information about other resources in the buildset, starting with the base security group - really just there to allow access to shared config information
# and web EC2 instance. Also setting u p vault provider for secrets retrieval
#
data "terraform_remote_state" "basesg" {
  backend = "local"

  config = {
    path = pathexpand("~/tofu/tofu-basesg.tfstate")
  }
}

data "terraform_remote_state" "web" {
  backend = "local"

  config = {
    path = pathexpand("~/tofu/tofu-web.tfstate")
  }
}

data "vault_generic_secret" "cloudflare-info" {
  path = "secret/cloudflare"
}

data "vault_generic_secret" "forge-info" {
  path = "secret/forge"
}
