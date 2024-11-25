# Import aws and datadog modules
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #      version = "~> 4.16"
    }
    datadog = {
      source = "datadog/datadog"
    }
  }
}
