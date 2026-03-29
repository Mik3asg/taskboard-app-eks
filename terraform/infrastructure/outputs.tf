// ─── VPC ──────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

// ─── EKS ──────────────────────────────────────────────────────────────────────

output "cluster_name" {
  description = "EKS cluster name — use with: aws eks update-kubeconfig --name <value>"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — needed for any additional IRSA roles created outside this module"
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

// ─── DNS ──────────────────────────────────────────────────────────────────────

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.dns.zone_id
}

output "name_servers" {
  description = "NS records to add to the parent zone (virtualscale.dev) for delegation"
  value       = module.dns.name_servers
}

// ─── IRSA ─────────────────────────────────────────────────────────────────────

output "external_dns_role_arn" {
  description = "IAM role ARN for ExternalDNS — annotate its service account with this value"
  value       = module.irsa_external_dns.role_arn
}

output "cert_manager_role_arn" {
  description = "IAM role ARN for cert-manager — annotate its service account with this value"
  value       = module.irsa_cert_manager.role_arn
}

// ─── GitHub Actions ───────────────────────────────────────────────────────────

output "github_terraform_role_arn" {
  description = "IAM role ARN for GitHub Actions Terraform pipeline — set as AWS_TERRAFORM_ROLE_ARN secret"
  value       = aws_iam_role.github_terraform.arn
}

output "github_cicd_role_arn" {
  description = "IAM role ARN for GitHub Actions CI/CD pipeline — set as AWS_CICD_ROLE_ARN secret"
  value       = aws_iam_role.github_cicd.arn
}

// ─── ECR ──────────────────────────────────────────────────────────────────────

output "ecr_frontend_url" {
  description = "ECR repository URL for the Plane frontend image"
  value       = aws_ecr_repository.plane_frontend.repository_url
}

output "ecr_backend_url" {
  description = "ECR repository URL for the Plane backend image"
  value       = aws_ecr_repository.plane_backend.repository_url
}

output "ecr_worker_url" {
  description = "ECR repository URL for the Plane worker image"
  value       = aws_ecr_repository.plane_worker.repository_url
}
