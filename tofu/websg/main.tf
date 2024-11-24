resource "aws_security_group" "web-sg" {
  name        = "${var.prefix}-web-tf-sg"
  description = "Rasmus Hald Terraform web SG"

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks  = local.cidrs
  }

  ingress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks  = local.cidrs
  }

  tags = { Name = "${var.prefix}-web-tf-sg" }
}
