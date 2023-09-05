output "s3_bucket" {
  description = "S3 Bucket Name"
  value       = module.s3_bucket.s3_bucket_id
}

output "irsa_role" {
  description = "ARN of the IRSA Role"
  value       = aws_iam_role.irsa[0].arn
}
