#
# Provide accessible information about the attached security groups, the nodename, and public/private IPs attached to the EC2
#
output "security_groups" {
  description = "Mapped Security Groups"
  value = local.sg
}
output "nodename" {
  description = "External DNS Name of the new node"
  value = "${local.name}.hald.id.au"
}
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.rhelclient.public_ip
}
output "instance_public_ip_cidr" {
  description = "Public IP address of the EC2 instance"
  value       = "${aws_instance.rhelclient.public_ip}/32"
}
output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.rhelclient.private_ip
}
