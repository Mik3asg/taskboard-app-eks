variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" { 
  description = "Project name"
  type        = string
  default     = "plane-app-eks"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
}

variable "domain_name" {
  description = "Route53 subdomain for ExternalDNS and CertManager"
  type        = string
  default     = "labs.virtualscale.dev"
}