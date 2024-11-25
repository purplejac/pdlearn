#
# Define an EC2 instance
#
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

  # Connect the volume block device as defined elsewhere
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

  #
  # Set up a standardised tag naming approach
  #
  tags = merge(
    {
      Name     = local.name
      lifetime = var.lifetime
    },
    var.tags
  )

  #
  # Setup an SSH connection for consumption with the remote-exec provisioner
  connection {
    type = "ssh"
    user = var.userid
    host = self.public_ip
    private_key = file("~/.ssh/${var.key_name}.pem")
  }

  user_data = var.user_data

  #
  # Setup post-build command set for installation of QloApps and the DataDog agent
  #
  # This could potentially be done better either with cloud-init or ansible/puppet. However, the set of commands is so short and there is no real need for ongoing enforcement 
  # for this particular usecase that it seemed like a bad choice to start installing ansible and writing playbooks purely for the purpose of running these installations.
  # Might look to migrate at a later point, if nothing else then simply to offer a better option for writing the apache config which is currently locked as a base64 encoded string.
  #
  provisioner "remote-exec" {
    inline = [
      "sudo add-apt-repository ppa:ondrej/php -y && sudo add-apt-repository ppa:ondrej/apache2 -y && sudo apt update -y",
      "sudo apt install -y apache2 php7.4 libapache2-mod-php7.4 php7.4-mysql php7.4-curl php7.4-gd php7.4-xml php7.4-mbstring php7.4-fpm php7.4-soap php7.4-zip git",
      "sudo sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 16M/g' /etc/php/7.4/apache2/php.ini /etc/php/7.4/fpm/php.ini /etc/php/cli/php.ini",
      "git clone https://github.com/Qloapps/QloApps.git",
      "sudo mv QloApps /var/www/html/qloapps",
      "sudo a2enmod rewrite",
      "echo 'PFZpcnR1YWxIb3N0ICo6ODA+CiAgICAgICAgU2VydmVyQWRtaW4gYWRtaW5AcWxvYXBwcy5jb20KICAgICAgICBEb2N1bWVudFJvb3QgL3Zhci93d3cvaHRtbC9xbG9hcHBzCiAgICAgICAgU2VydmVyTmFtZSBwZC13ZWItMDEuaGFsZC5pZC5hdQogICAgICAgIFNlcnZlckFsaWFzIHd3dy55b3VyZG9tYWluLmNvbQo8RGlyZWN0b3J5IC92YXIvd3d3L2h0bWwvcWxvYXBwcy8+CiAgICAgICAgT3B0aW9ucyBGb2xsb3dTeW1MaW5rcwogICAgICAgIEFsbG93T3ZlcnJpZGUgQWxsCiAgICAgICAgUmVxdWlyZSBhbGwgZ3JhbnRlZAo8L0RpcmVjdG9yeT4KICAgICAgICBFcnJvckxvZyAke0FQQUNIRV9MT0dfRElSfS9lcnJvci5sb2cKICAgICAgICBDdXN0b21Mb2cgJHtBUEFDSEVfTE9HX0RJUn0vYWNjZXNzLmxvZyBjb21iaW5lZAo8L1ZpcnR1YWxIb3N0Pgo=' | base64 -d | sudo tee /etc/apache2/sites-available/000-qloapps.conf",
      "sudo a2ensite 000-qloapps.conf",
      "sudo chown -R www-data:www-data /var/www/html/qloapps",
      "DD_API_KEY=<DATADOG_API_KEY> DD_SITE=\"ap1.datadoghq.com\" bash -c \"$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)\""
    ]
  }
}

# Create a cloudflare entry in the domain, pointing to the new EC2 instance
resource "cloudflare_record" "rhelclient-entry" {
  zone_id = var.dns_zone_id
  name    = local.name
  value   = aws_instance.rhelclient.public_ip
  type    = "A"
  ttl     = 1
  allow_overwrite = true

  #  depends_on = [aws_instance.rhelclient]
}
