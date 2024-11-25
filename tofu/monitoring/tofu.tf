# Export the state for any potential future needs
terraform {
  backend "local" {
    path = "/Users/nebakke/tofu/tofu-monitoring.tfstate"
  }
}
