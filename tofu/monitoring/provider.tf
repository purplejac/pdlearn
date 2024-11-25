# Configure AWS provider with shared information
provider "aws" {
  profile = data.terraform_remote_state.basesg.outputs.aws_profile
  region  = data.terraform_remote_state.basesg.outputs.aws_region
}
