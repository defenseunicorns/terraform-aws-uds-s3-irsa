variable "app" {
  description = "Application name"
  type        = list(string)
  default     = ["my-app"]
}

variable "name_prefix" {
  description = "Name prefix for all resources that use a randomized suffix"
  type        = string
  validation {
    condition     = length(var.name_prefix) <= 37
    error_message = "Name Prefix may not be longer than 37 characters."
  }
}

variable "irsa_iam_policies" {
  type        = list(string)
  description = "IAM Policies for IRSA IAM role"
  default     = []
}

variable "irsa_iam_role_path" {
  description = "IAM role path for IRSA roles"
  type        = string
  default     = "/"
}

variable "irsa_iam_permissions_boundary" {
  description = "IAM permissions boundary for IRSA roles"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "access_logging_enabled" {
  description = "If true, set up access logging of the S3 bucket to a different S3 bucket, provided by the variables `logging_bucket_id` and `logging_bucket_path`. Caution: Enabling this will likely cause LOTS of access logs, as one is generated each time the bucket is accessed and Loki will be hitting the bucket a lot!"
  type        = bool
  default     = false
}

variable "access_logging_bucket_id" {
  description = "The ID of the S3 bucket to which access logs are written"
  type        = string
  default     = null
}

variable "access_logging_bucket_prefix" {
  description = "The prefix to use for all log object keys. Ex: 'logs/'"
  type        = string
  default     = "s3-irsa-bucket-access-logs/"
}

variable "force_destroy" {
  description = "If true, destroys all objects in the bucket when the bucket is destroyed so that the bucket can be destroyed without error. Objects that are destroyed in this way are NOT recoverable."
  type        = bool
  default     = false
}

variable "iam_role_permissions_boundary" {
  description = "Permissions boundary for the IAM role"
  type        = string
  default     = ""
}

variable "key_owner_arns" {
  description = "List of ARNs of the AWS accounts that should have access to the KMS key"
  type        = list(string)
  default     = []
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket to store Terraform state"
  type        = string
  default     = ""
}

variable "eks_state_key" {
  description = "Path to the EKS terraform state file inside the S3 bucket"
  type        = string
  default     = ""
}
