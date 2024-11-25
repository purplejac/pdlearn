#
# Setup outputs of connected security groups, nodename(s) and the private IP for integration with other security groups
#
output "security_groups" {
  description = "Mapped Security Groups"
  value = local.sg
}
output "nodenames" {
  description = "External DNS Name of the new node"
  value       = ["${module.clientnode.*.nodename}"]
}
output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.clientnode.*.instance_private_ip
}
