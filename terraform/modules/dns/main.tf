// Public hosted zone for the subdomain used by ExternalDNS and cert-manager.
// After apply, delegate this zone from the parent domain by copying the NS records
// into the parent zone (e.g. virtualscale.dev → add labs NS records pointing here).
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = var.domain_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
