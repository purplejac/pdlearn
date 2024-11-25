#
# Declare a RDS instance and configure a default database for integration with QloApps
# have defaulted a security group here. Best practice would have it be a lookup, but 
# as a short-term solution, this is functional.
#
resource "aws_db_instance" "pjdb" {
  allocated_storage = 5
  engine = "mariadb"
  instance_class = "db.t3.micro"
  username = <USERNAME>
  password = <PASSWORD>
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.db-sg.id, "sg-0434cbabdb42ee100"]
  db_name = "qlodb"
  tags = { Name = "pd-db-01" }
}

#
# Add a domain name to the instance. It is not externally accessible, but the domain name
# simplifies the connectivity configuration from the webserver
#
resource "cloudflare_record" "pjdb-entry" {
  zone_id = var.dns_zone_id
  name    = "pd-pjdb-01"
  value   = aws_db_instance.pjdb.address
  type    = "CNAME"
  ttl     = 1
  allow_overwrite = true

  depends_on = [aws_db_instance.pjdb]
}

#
# Establish a security group to allow incoming access on 3306. Egress could be locked down harder,
# but for a PoC build this ensures access quickly.
#
resource "aws_security_group" "db-sg" {
  name        = "pd-tf-db-sg"
  description = "Ras Tofu DB Security Group"
  tags = { Name = "pd-tf-db-sg" }

  egress {
    description = "Outbount Access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Database traffic from private"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my-ip.result.ip}/32", "${data.terraform_remote_state.web.outputs.instance_private_ip[0]}/32"]
  }
}