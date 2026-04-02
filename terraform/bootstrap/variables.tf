variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "taskboard-app-eks"
}
