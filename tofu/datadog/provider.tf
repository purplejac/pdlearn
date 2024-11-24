provider "aws" {
  profile = data.terraform_remote_state.basesg.outputs.aws_profile #var.aws_profile
  region  = data.terraform_remote_state.basesg.outputs.aws_region  # var.aws_region
}
provider "datadog" {
  api_url = "https://api.ap1.datadoghq.com"
  api_key = "a35dd92317089ee75ba8fa633d2b7216"
  app_key = "10860c985b31cce23d21b96fa373875ef09e530f"
}
