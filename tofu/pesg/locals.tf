locals {
  cdips = try(data.terraform_remote_state.cd4pe.outputs.instance_public_ip_cidrs, "")
  cidrone = data.external.my-ip.result.ip == "" ? ["172.31.0.0/16"] : ["${data.external.my-ip.result.ip}/32","172.31.0.0/16"]
  cidrs = local.cdips == "" ? local.cidrone : concat(local.cidrone,[local.cdips])
}
