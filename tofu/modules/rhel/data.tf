data "terraform_remote_state" "basesg" {
  backend = "local"

  config = {
    path = "/Users/nebakke/tofu/tofu-basesg.tfstate"
  }
}
data "vault_generic_secret" "cloudflare-info" {
  path = "secret/cloudflare"
}
