#
# Create baseline security group, allowing all access out from the hosts
# and allowing incoming SSH/RDP and WinRM (where relevant)
# 
resource "aws_security_group" "baseline-sg" {
  name        = "${var.prefix}-baseline-tf-sg"
  description = "Rasmus Hald Tofu baseline SG"

  egress {
    description = "Outbound Access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.prefix}-baseline-tf-sg" }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16", "${data.external.my-ip.result.ip}/32"]
  }

  ingress {
    description = "RDP Access from IP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my-ip.result.ip}/32"]
  }

  ingress {
    description = "WinRM Access"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my-ip.result.ip}/32", "172.31.0.0/16"]
  }
}
