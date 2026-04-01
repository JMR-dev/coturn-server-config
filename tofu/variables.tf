variable "gcp_project" {
  description = "GCP project ID used for provider-scoped resources."
  type        = string
}

variable "gcp_region" {
  description = "GCP region used for regional resources."
  type        = string
}

variable "gcp_zone" {
  description = "GCP zone used for the relay instance."
  type        = string
}

variable "network_name" {
  description = "VPC network name."
  type        = string
  default     = "default"
}

variable "instance_name" {
  description = "Name of the relay VM."
  type        = string
  default     = "relay-main"
}

variable "machine_type" {
  description = "GCP machine type for the relay."
  type        = string
  default     = "e2-micro"
}

variable "admin_ssh_public_key" {
  description = "Optional SSH public key injected for the ubuntu user."
  type        = string
  default     = ""
}
