variable "cidr_block" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.0.0/16"
}

variable "public_ip_on_launch" {
  type        = bool
  description = "Assign Public IP for new instances launched into that subnet"
  default     = false
}