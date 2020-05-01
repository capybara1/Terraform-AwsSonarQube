variable "aws_profile" {
  description = "The AWS CLI profile."
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "The AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "prefix" {
  description = "The common prefix for names."
  type        = string
  default     = "SonarQube"
}

variable "ssh_whitelist" {
  description = "Whitelist of cidr blocks for access to the server"
  type        = set(string)
  default     = ["0.0.0.0/0"] # Access required for SSH
}

variable "vpc_cidr_block" {
  description = "The VPC network."
  type        = string
  default     = "10.0.0.0/24"
}

variable "service_domain" {
  description = "The DNS domain resolving to the server ip."
  type        = string
}

variable "cert_domain" {
  description = "The DNS domain of the certificate in AWS Certificate Manager."
  type        = string
}

variable "zone" {
  description = "The name of the DNS zone in AWS Route53."
  type        = string
}

variable "public_key_path" {
  description = "Path to the RSA public key."
  type        = string
}

variable "instance_type" {
  description = "AWS EC2 instance type."
  type        = string
  default     = "t3a.medium"
}

variable "instance_root_volume_size" {
  description = "AWS EC2 instance root volume size."
  type        = number
  default     = 10
}
