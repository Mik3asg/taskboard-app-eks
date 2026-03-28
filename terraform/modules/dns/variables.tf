variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "The DNS zone to create (e.g. labs.virtualscale.dev)"
  type        = string
}
