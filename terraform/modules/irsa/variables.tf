variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "role_name" {
  description = "Short name for this role (e.g. 'external-dns', 'cert-manager') — appended to the full role name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider — from the EKS module output"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL — from the EKS module output (without https://)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace the service account lives in"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name that will assume this role"
  type        = string
}

variable "policy_arns" {
  description = "List of managed IAM policy ARNs to attach to the role (use for AWS-managed policies)"
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline IAM policy document as JSON (use for custom permissions)"
  type        = string
  default     = null
}
