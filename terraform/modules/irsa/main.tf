// Strip the "https://" prefix from the issuer URL — the OIDC condition key uses
// the bare hostname + path (e.g. oidc.eks.eu-west-2.amazonaws.com/id/EXAMPL...)
locals {
  oidc_issuer_bare = replace(var.oidc_issuer_url, "https://", "")
}

// ─── IAM Role ─────────────────────────────────────────────────────────────────

// Trust policy: only the specific service account in the specific namespace
// can assume this role. The "sub" condition prevents any other pod in the
// cluster from using it, even if they have the right OIDC token.
resource "aws_iam_role" "this" {
  name = "${var.project_name}-${var.environment}-${var.role_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          // Scope to the exact service account — prevents privilege escalation
          // from other pods in the same namespace
          "${local.oidc_issuer_bare}:sub" = "system:serviceaccounts:${var.namespace}:${var.service_account_name}"
          // Scope to AWS STS — prevents token reuse against other OIDC relying parties
          "${local.oidc_issuer_bare}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.role_name}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    // Record which service account uses this role — makes auditing easy
    KubeServiceAccount = "${var.namespace}/${var.service_account_name}"
  }
}

// ─── Policy Attachments ───────────────────────────────────────────────────────

// Attach one or more managed policies (e.g. AWS-managed Route53 policies)
// for_each on a set means we can attach 0, 1, or many policies cleanly
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

// Attach an inline policy when the caller provides a custom JSON document
// (e.g. a fine-grained Route53 policy scoped to a specific hosted zone)
resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json != null ? 1 : 0

  name   = "${var.project_name}-${var.environment}-${var.role_name}-policy"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
