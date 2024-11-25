#
# Adding in the basesg purely to provide access to the shared aws configuration information
#
data "terraform_remote_state" "basesg" {
  backend = "local"

  config = {
    path = pathexpand("~/tofu/tofu-basesg.tfstate")
  }
}
