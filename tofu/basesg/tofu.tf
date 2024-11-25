#
# Setup the terraform backend storage for shared data
#
terraform {
  backend "local" {
    path = pathexpand("~/tofu/tofu-basesg.tfstate")
  }
}
