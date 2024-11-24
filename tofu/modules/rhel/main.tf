resource "aws_instance" "rhelclient" {
  ami                         = var.ami
  associate_public_ip_address = true
  instance_type               = var.instance_type
  depends_on                  = [data.terraform_remote_state.basesg]

  security_groups             = local.sg
  key_name                    = var.key_name

  lifecycle {
    ignore_changes = [
      tags["termination_date"],
    ]
  }

  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true

    tags = merge(
      {
        Name     = local.volname
        lifetime = var.lifetime
      },
      var.tags
    )
  }

  tags = merge(
    {
      Name     = local.name
      lifetime = var.lifetime
    },
    var.tags
  )

  connection {
    type = "ssh"
    user = var.userid
    host = self.public_ip
    private_key = file("~/.ssh/${var.key_name}.pem")
  }

  user_data = var.user_data

  provisioner "remote-exec" {
    inline = [
      "sudo add-apt-repository ppa:ondrej/php -y && sudo add-apt-repository ppa:ondrej/apache2 -y && sudo apt update -y",
      "sudo apt install -y apache2 php7.4 libapache2-mod-php7.4 php7.4-mysql php7.4-curl php7.4-gd php7.4-xml php7.4-mbstring php7.4-fpm php7.4-soap php7.4-zip git",
      "sudo sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 16M/g' /etc/php/7.4/apache2/php.ini /etc/php/7.4/fpm/php.ini /etc/php/cli/php.ini",
      #      "sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm",
      #"sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm",
      #"sudo dnf module enable php:remi-7.4 -y",
      #      "sudo dnf install -y httpd php php-cli php-common php-mysqlnd php-gd git",
      "git clone https://github.com/Qloapps/QloApps.git",
      "sudo mv QloApps /var/www/html/qloapps",
      "sudo a2enmod rewrite",
      "echo 'PFZpcnR1YWxIb3N0ICo6ODA+CiAgICAgICAgU2VydmVyQWRtaW4gYWRtaW5AcWxvYXBwcy5jb20KICAgICAgICBEb2N1bWVudFJvb3QgL3Zhci93d3cvaHRtbC9xbG9hcHBzCiAgICAgICAgU2VydmVyTmFtZSBwZC13ZWItMDEuaGFsZC5pZC5hdQogICAgICAgIFNlcnZlckFsaWFzIHd3dy55b3VyZG9tYWluLmNvbQo8RGlyZWN0b3J5IC92YXIvd3d3L2h0bWwvcWxvYXBwcy8+CiAgICAgICAgT3B0aW9ucyBGb2xsb3dTeW1MaW5rcwogICAgICAgIEFsbG93T3ZlcnJpZGUgQWxsCiAgICAgICAgUmVxdWlyZSBhbGwgZ3JhbnRlZAo8L0RpcmVjdG9yeT4KICAgICAgICBFcnJvckxvZyAke0FQQUNIRV9MT0dfRElSfS9lcnJvci5sb2cKICAgICAgICBDdXN0b21Mb2cgJHtBUEFDSEVfTE9HX0RJUn0vYWNjZXNzLmxvZyBjb21iaW5lZAo8L1ZpcnR1YWxIb3N0Pgo=' | base64 -d | sudo tee /etc/apache2/sites-available/000-qloapps.conf",
      "sudo a2ensite 000-qloapps.conf",
      "sudo chown -R www-data:www-data /var/www/html/qloapps",
      "DD_API_KEY=a35dd92317089ee75ba8fa633d2b7216 DD_SITE=\"ap1.datadoghq.com\" bash -c \"$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)\""
      #      "sudo setenforce 0",
      #      "sudo systemctl enable --now php-fpm",
      #      "sudo systemctl enable --now httpd",
    ]
  }
}

resource "cloudflare_record" "rhelclient-entry" {
  zone_id = var.dns_zone_id
  name    = local.name
  value   = aws_instance.rhelclient.public_ip
  type    = "A"
  ttl     = 1
  allow_overwrite = true

  #  depends_on = [aws_instance.rhelclient]
}
