#
# Setup locals to build the automated naming, volume naming and security group mappings
#
locals {
  dirname       = split("/", path.cwd)[(length(split("/", path.cwd)) - 1)]
  name          = var.node_count < 10 ? "${var.prefix}-${local.dirname}-0${var.node_count}" : "${var.prefix}-${var.name}-${var.node_count}"
  volname       = "${local.name}-vol"
  base_sg       = var.sg == tolist([]) ? data.terraform_remote_state.basesg.outputs.sg-names : var.sg
  sg            = local.base_sg # concat(local.base_sg, data.terraform_remote_state.websg.outputs.sg-names) 
}
