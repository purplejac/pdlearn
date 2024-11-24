data "external" "my-ip" {
  program = ["/usr/bin/curl", "--connect-timeout", "180", "https://api64.ipify.org?format=json"]
}
