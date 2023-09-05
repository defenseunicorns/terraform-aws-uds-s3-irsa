locals {
  eks_oidc_issuer_url = replace(var.eks_oidc_provider_arn, "/^(.*provider/)/", "")
  kms_key_alias_name_prefix  = "alias/${var.name_prefix}-${lower(random_id.default.hex)}"
  generate_kms = var.create_kms_key ? 1 : 0
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

#####################################################
#################### S3 Bucket ######################
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "v3.15.1"

  bucket_prefix           = var.name_prefix
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy           = var.force_destroy

  tags = var.tags
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.generate_kms[0].kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "random_id" "default" {
  byte_length = 2
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = module.s3_bucket.s3_bucket_id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "logging" {
  count = var.access_logging_enabled ? 1 : 0

  bucket        = module.s3_bucket.s3_bucket_id
  target_bucket = var.access_logging_bucket_id
  target_prefix = var.access_logging_bucket_prefix

  depends_on = [module.s3_bucket.s3_bucket_id]

  lifecycle {
    precondition {
      condition     = var.access_logging_bucket_id != null && var.access_logging_bucket_prefix != null
      error_message = "access_logging_bucket_id and access_logging_bucket_path must be set to enable access logging."
    }
  }
}

data "aws_iam_policy_document" "irsa_policy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [module.s3_bucket.s3_bucket_arn]
  }
  statement {
    actions   = ["s3:*Object"]
    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]
  }
  statement {
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [module.generate_kms[0].kms_key_arn]
  }
}

resource "aws_iam_policy" "irsa_policy" {
  description = "IAM Policy for IRSA"
  name_prefix = "${var.name_prefix}-${var.policy_name_prefix}"
  policy      = data.aws_iam_policy_document.irsa_policy.json
}

resource "aws_iam_role" "irsa" {
  count = var.irsa_iam_policies != null ? 1 : 0

  name        = try(coalesce(var.irsa_iam_role_name, format("%s-%s-%s", var.name_prefix, trim(var.kubernetes_service_account, "-*"), "irsa")), null)
  description = "AWS IAM Role for the Kubernetes service account ${var.kubernetes_service_account}."
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : var.eks_oidc_provider_arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "${local.eks_oidc_issuer_url}:sub" : "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}",
            "${local.eks_oidc_issuer_url}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  path                  = var.irsa_iam_role_path
  force_detach_policies = true
  permissions_boundary  = var.iam_role_permissions_boundary

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "irsa" {

  policy_arn = aws_iam_policy.irsa_policy.arn
  role       = aws_iam_role.irsa[0].name
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  # count  = local.create_bucket_policy ? 1 : 0
  bucket = module.s3_bucket.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.irsa[0].arn
        }
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

################################################################################
# DynamoDB Table
################################################################################

module "generate_kms" {
  count  = local.generate_kms
  source = "github.com/defenseunicorns/terraform-aws-uds-kms?ref=v0.0.2"

  key_owners = var.key_owner_arns
  # A list of IAM ARNs for those who will have full key permissions (`kms:*`)
  kms_key_alias_name_prefix = "${local.kms_key_alias_name_prefix}" # Prefix for KMS key alias.
  kms_key_deletion_window   = 7
  # Waiting period for scheduled KMS Key deletion. Can be 7-30 days.
  tags = {
    Deployment = "UDS DUBBD ${var.name_prefix}"
  }
}
