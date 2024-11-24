variable "prefix" {
  description = "Naming prefix to use for builds etc."
  type        = string
  default     = "ras"
}

variable "my-ip" {
  description = "IP to add to the allow clause"
  type        = string
  default     = "180.150.28.33/32"
}
