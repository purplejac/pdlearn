resource "cloudflare_record" "pjdb-entry" {
  zone_id = var.dns_zone_id
  name    = "pd-pjdb-01"
  value   = aws_db_instance.pjdb.address
  type    = "CNAME"
  ttl     = 1
  allow_overwrite = true

  depends_on = [aws_db_instance.pjdb]
}

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

resource "aws_db_instance" "pjdb" {
  allocated_storage = 5
  engine = "mariadb"
  instance_class = "db.t3.micro"
  username = "purplejac"
  password = "t0ps3cr3t!"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.db-sg.id, "sg-0434cbabdb42ee100"]
  db_name = "qlodb"
  tags = { Name = "pd-db-01" }
}
