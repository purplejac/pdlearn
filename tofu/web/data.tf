data "external" "my-ip" {
  program = ["/usr/bin/curl", "--connect-timeout", "180", "https://api64.ipify.org?format=json"]
}
data "terraform_remote_state" "basesg" {
  backend = "local"

  config = {
    path = "/Users/nebakke/tofu/tofu-basesg.tfstate"
  }
}
data "vault_generic_secret" "cloudflare-info" {
  path = "secret/cloudflare"
}
data "vault_generic_secret" "forge-info" {
  path = "secret/forge"
}
