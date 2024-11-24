locals {
  cdcidr = try(data.terraform_remote_state.cd4pe.outputs.instance_public_ip_cidr,"")
  cidrone = data.external.my-ip.result.ip == "" ? ["172.31.0.0/16"] : ["${data.external.my-ip.result.ip}/32","172.31.0.0/16"]
  cidrtwo = try(data.terraform_remote_state.infra.outputs.infrance_public_ip_cidrs,"") == "" ? local.cidrone : concat(local.cidrone,data.terraform_remote_state.infra.outputs.instance_public_ip_cidrs)
  cidrs = local.cdcidr == "" ? local.cidrone : concat(local.cidrtwo,[local.cdcidr])
}
