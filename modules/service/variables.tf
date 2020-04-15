variable "prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "subnet" {
  type = object({id = string, availability_zone_id = string})
}

variable "service_domain" {
  type = string
}

variable "ssh_whitelist" {
  type = set(string)
}

variable "public_key_path" {
  type = string
}

variable "instance_type" {
  type = string
}
