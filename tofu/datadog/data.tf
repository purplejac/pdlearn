data "terraform_remote_state" "basesg" {
  backend = "local"

  config = {
    path = pathexpand("~/tofu/tofu-basesg.tfstate")
  }
}
