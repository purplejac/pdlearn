#
# Primary EC2 instance setup
#

#
# Build the web security group to allow HTTP(S) access to the webserver
#
resource "aws_security_group" "web-sg" {
  name        = "${var.prefix}-web-tf-sg"
  description = "Rasmus Hald Terraform web SG"

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #    cidr_blocks  = local.cidrs
  }

  ingress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks  = local.cidrs
  }

  tags = { Name = "${var.prefix}-web-tf-sg" }
}

#
# Call out to the clientnode builder to build the EC2 and connect the security groups and volumes
#
module "clientnode" {
  source = "../modules/rhel"

  count = var.node_count

  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  lifetime      = var.lifetime
  name          = local.dirname
  postfix       = (count.index + 1)
  prefix        = var.prefix
  sg            = concat(local.sg, [aws_security_group.web-sg.name])
  tags          = var.tags

  depends_on = [data.terraform_remote_state.basesg, aws_security_group.web-sg]

}
