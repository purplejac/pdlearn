resource "aws_security_group" "pe-sg" {
  name        = "${var.prefix}-pe-tf-sg"
  description = "Rasmus Hald Terraform PE SG"

  ingress {
    description = "PE HTTPS Console Access"
    from_port   = 4433
    to_port     = 4433
    protocol    = "tcp"
    cidr_blocks  = ["${data.external.my-ip.result.ip}/32", "172.31.0.0/16"]
  }

  ingress {
    description = "Postgres Access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks  = local.cidrs
  }

  ingress {
    description = "PuppetDB Interaction"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks  = local.cidrs
  }

  ingress {
    description = "Puppet Agent Traffic"
    from_port   = 8140
    to_port     = 8140
    protocol    = "tcp"
    cidr_blocks  = local.cidrs
  }

  ingress {
    description = "Orchestrator Broker Interaction"
    from_port   = 8143
    to_port     = 8143
    protocol    = "tcp"
    cidr_blocks  = local.cidrs
  }

  ingress {
    description = "Code Manager Access"
    from_port   = 8170
    to_port     = 8170
    protocol    = "tcp"
    cidr_blocks  = local.cidrs
  }

  tags = { Name = "${var.prefix}-pe-tf-sg" }
}
