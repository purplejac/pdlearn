# AWS Variables

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "AWS Profile"
  type        = string
  default     = "default"
}

variable "prefix" {
  description = "Naming prefix to use for builds etc."
  type        = string
  default     = "ras"
}
