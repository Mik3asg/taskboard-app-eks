// ─── VPC ──────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  cluster_name = "${var.project_name}-${var.environment}"
}

// ─── EKS ──────────────────────────────────────────────────────────────────────

module "eks" {
  source = "../modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

// ─── DNS ──────────────────────────────────────────────────────────────────────

module "dns" {
  source = "../modules/dns"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
}

// ─── IRSA: ExternalDNS ────────────────────────────────────────────────────────

// ExternalDNS needs to write A records into the hosted zone when Ingress
// resources are created. Scoping to the specific zone ID prevents it from
// modifying any other zones in the account.
module "irsa_external_dns" {
  source = "../modules/irsa"

  project_name         = var.project_name
  environment          = var.environment
  role_name            = "external-dns"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_issuer_url      = module.eks.cluster_oidc_issuer_url
  namespace            = "external-dns"
  service_account_name = "external-dns"

  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/${module.dns.zone_id}"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets"]
        Resource = ["*"]
      }
    ]
  })
}

// ─── IRSA: cert-manager ───────────────────────────────────────────────────────

// cert-manager uses the DNS-01 ACME challenge to prove domain ownership to
// Let's Encrypt. It creates a TXT record in Route53, waits for validation,
// then removes it. GetChange is needed to poll until the record propagates.
module "irsa_cert_manager" {
  source = "../modules/irsa"

  project_name         = var.project_name
  environment          = var.environment
  role_name            = "cert-manager"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_issuer_url      = module.eks.cluster_oidc_issuer_url
  namespace            = "cert-manager"
  service_account_name = "cert-manager"

  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = ["arn:aws:route53:::change/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/${module.dns.zone_id}"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZonesByName"]
        Resource = ["*"]
      }
    ]
  })
}

// ─── GitHub Actions: OIDC + IAM Roles ────────────────────────────────────────

// One-time OIDC provider that lets GitHub Actions assume AWS roles via short-lived
// tokens — no long-lived AWS access keys stored in GitHub secrets.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

locals {
  github_oidc_arn = aws_iam_openid_connect_provider.github.arn
  github_sub      = "repo:${var.github_repo}:*"
}

// Terraform pipeline role — broad permissions needed to manage all infra resources
resource "aws_iam_role" "github_terraform" {
  name = "github-actions-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = local.github_oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = local.github_sub }
      }
    }]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_terraform_admin" {
  role       = aws_iam_role.github_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

// CI/CD pipeline role — ECR push + EKS describe for image builds and ArgoCD sync
resource "aws_iam_role" "github_cicd" {
  name = "github-actions-cicd"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = local.github_oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = local.github_sub }
      }
    }]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_cicd_ecr" {
  role       = aws_iam_role.github_cicd.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "github_cicd_eks" {
  role       = aws_iam_role.github_cicd.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

// ─── ECR Repositories ─────────────────────────────────────────────────────────

// One repo per Plane service. The CI pipeline builds, tags, and pushes images
// here; the K8s manifests reference these repos via the outputs below.
resource "aws_ecr_repository" "plane_frontend" {
  name                 = "${var.project_name}/plane-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_repository" "plane_backend" {
  name                 = "${var.project_name}/plane-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_repository" "plane_worker" {
  name                 = "${var.project_name}/plane-worker"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
