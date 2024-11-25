#
# Build the basic name, volume mount reference and security group sets for local consumption
#
locals {
  name          = var.postfix < 10 ? "${var.prefix}-${var.name}-0${var.postfix}" : "${var.prefix}-${var.name}-${var.postfix}"
  volname       = "${local.name}-vol"
  sg            = length(var.sg) == 0  ? data.terraform_remote_state.basesg.outputs.sg-names : var.sg
}
