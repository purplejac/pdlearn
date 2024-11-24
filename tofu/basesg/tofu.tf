terraform {
  backend "local" {
    path = pathexpand("~/tofu/tofu-basesg.tfstate")
  }
}
