variable "project" {
  description = "the GCP project ID"
  type        = string
}
variable "vpc" {
  description = "the vpc name"
  type        = string
}

variable "region" {
  description = "the region of the instance"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "the zone of the instance"
  type        = string
  default     = "us-central1-b"
}

variable "range" {
  description = "the cidr range for the subnet(s)"
  type = string
}

variable "subnet" {
  description = "the subnet(s) for this deployment"
  type = string
}

variable "allowed_source_ranges" {
  description = "List of IP ranges to allow ingress traffic from"
  type        = list(string)  
}

variable "couch_user" {
  description = "CouchDB username"
  type      = string
  sensitive = true
  default = "admin"
}

variable "couch_pass" {
  description = "CouchDB password"
  type      = string
  sensitive = true
  default = "pass"
}