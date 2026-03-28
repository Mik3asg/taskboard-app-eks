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

variable "cluster_name" {
  description = "EKS cluster version"
  type        = string
  default     = "plane-app-eks"
}