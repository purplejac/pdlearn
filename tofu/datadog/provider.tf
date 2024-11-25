# Configure AWS and Datadog providers
provider "aws" {
  profile = data.terraform_remote_state.basesg.outputs.aws_profile
  region  = data.terraform_remote_state.basesg.outputs.aws_region
}
provider "datadog" {
  api_url = "https://api.ap1.datadoghq.com"
  api_key = <API_KEY>
  app_key = <APP_KEY>
}
