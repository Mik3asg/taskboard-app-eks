// Create a S3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state"

  #checkov:skip=CKV_AWS_144: "Cross-region replication is unnecessary for a self-training state bucket"
  #checkov:skip=CKV2_AWS_62: "Event notifications are not required for a Terraform state bucket"
  #checkov:skip=CKV_AWS_18:  "Access logging adds cost and complexity not warranted for a self-training project"
  #checkov:skip=CKV_AWS_145: "AES256 server-side encryption is sufficient; KMS adds cost and complexity"
  #checkov:skip=CKV2_AWS_61: "State files do not require a lifecycle expiry policy"

  // Prevent accidental deletion of state bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project     = var.project_name
    Environment = "bootstrap"
    ManagedBy   = "terraform"
  }
}

// Enable S3 bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

// Enable server-side-encryption on S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// Public access block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
