variable "aws_profile" {
  description = "The AWS CLI profile."
  default     = "default"
}

variable "aws_region" {
  description = "The AWS region."
  default     = "eu-central-1"
}

variable "prefix" {
  description = "The common prefix for names."
  default     = "Jitsi"
}

variable "vpc_cidr_block" {
  description = "The VPC network."
  default = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "The number of public subnets."
  default = 2
}

variable "private_subnet_count" {
  description = "The number of private subnets."
  default = 2
}

variable "domain" {
  description = "The DNS domain."
}

variable "zone" {
  description = "The DNS domain."
  default     = "${var.domain}."
}

variable "key_name" {
  description = "The name of the RSA key pair in AWS."
  default     = "SonarQube-Keys"
}

variable "public_key_path" {
  description = "Path to the RSA public key."
}

variable "instance_type" {
  description = "AWS EC2 instance type."
  default = "t3a.medium"
}
