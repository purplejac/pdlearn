output "aws_region" {
  description = "The AWS region in use."
  value       = var.aws_region
}

output "aws_profile" {
  description = "The in-use AWS profile"
  value       = var.aws_profile
}

output "sg-names" {
  value = [aws_security_group.web-sg.name]
}
