variable "ami" {
  description = "AMI ID"
  type        = string
  #default     = "ami-0c470b32d41481ad6"
  #default = "ami-0df71cd6f9c048a63"
  #default = "ami-08e0054de87d9d01a" # Rocky 9
  #default = "ami-001eae8c9920b7dab" # RHEL-9.5
  #default = "ami-00902d02d7a700776" # Debian 12
  default = "ami-040e71e7b8391cae4" # Ubuntu 22.04
}

variable "node_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "dns_zone_id" {
  description = "DNS Zone ID"
  type        = string
  default     = "cde8df30f406267584f4df6dd7669fb5"
}

variable "instance_type" {
  description = "EC2 Instance type for the client node."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name for the AWS key-pair to use for authentication."
  type        = string
  default     = "pj-aws"
}

variable "lifetime" {
  description = "Instance lifetime"
  type        = string
  default     = "1w"
}

variable "name" {
  description = "Value of the Name tag for the EC2 instance."
  type        = string
  default     = "linuxclient"
}

variable "postfix" {
  description = "Number to append to instance name."
  type        = number
  default     = 1
}

variable "prefix" {
  description = "Prefix to prepend on the hostname."
  type        = string
  default     = "pd"
}

variable "set_name" {
  description = "Override certname."
  type        = bool
  default     = true
}

variable "sg" {
  description = "List of applicable security groups."
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Applicable resource tags."
  type        = map(string)
  default = {
    created_by  = "rasmus@hald.id.au"
    department  = "Home"
    user        = "Rasmus Hald"
    environment = "testing"
  }
}

variable "userid" {
  description = "Default username for SSH auth against the node/AMI"
  type        = string
  default     = "ubuntu"
}

variable "user_data" {
  description = "User data to be executed at build-time."
  type        = string
  default     = ""
}

variable "volume_type" {
  description = "Volume type for the root block-device."
  type        = string
  default     = "gp2"
}

variable "volume_size" {
  description = "Size of the root volume in GB."
  type        = number
  default     = 10
}