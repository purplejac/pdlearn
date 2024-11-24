data "external" "my-ip" {
  program = ["/usr/bin/curl", "--connect-timeout", "180", "https://api64.ipify.org?format=json"]
}
data "terraform_remote_state" "cd4pe" {
  backend = "local"

  config = {
    path = "/Users/ras/terraform/terraform-cd4pe.tfstate"
  }
}
