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
