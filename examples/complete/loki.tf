# terraform {
#   backend "s3" {
#   }
# }

data "terraform_remote_state" "eks_cluster" {
  backend = "s3"
  config = {
    bucket = "###ZARF_VAR_STATE_BUCKET_NAME###"
    key    = "###ZARF_VAR_VPC1_NAME###/###ZARF_VAR_EKS_CLUSTER1_NAME###/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

data "aws_region" "current" {}

module "loki_s3_bucket" {
  # source = "git::https://github.com/defenseunicorns/delivery-aws-iac.git//modules/s3-irsa?ref=v<insert tagged version>"
  source = "../../"

  name_prefix                   = "${local.loki_name_prefix}-s3"
  region                        = data.aws_region.current.name
  policy_name_prefix            = "${local.loki_name_prefix}-s3-policy"
  kubernetes_service_account    = "logging-loki" #Must be logging-loki to match BigBang deployment
  kubernetes_namespace          = "logging"
  irsa_iam_role_name            = "${data.terraform_remote_state.eks_cluster.outputs.eks_cluster_name}-logging-loki-sa-role"
  irsa_iam_permissions_boundary = var.iam_role_permissions_boundary
  eks_oidc_provider_arn         = data.terraform_remote_state.eks_cluster.outputs.eks_oidc_provider_arn
  tags                          = local.tags
  create_kms_key                = true
  force_destroy                 = var.force_destroy
}

resource "random_id" "default" {
  byte_length = 2
}
