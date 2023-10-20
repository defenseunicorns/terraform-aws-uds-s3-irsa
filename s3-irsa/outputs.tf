output "s3_bucket" {
  description = "S3 Bucket Name"
  value       = module.s3_bucket[*].s3_bucket_id
}

output "irsa_role_arn" {
  description = "ARN of the IRSA Role"
  value       = aws_iam_role.irsa[*].arn
}

output "region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

output "force_destroy" {
  value = var.force_destroy
}