variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-2"
}

variable "name_prefix" {
  description = "Prefix to use for all resources in this module"
  type        = string
  default     = "my-loki"
}

variable "irsa_iam_permissions_boundary" {
  description = "Permissions boundary to use for the IRSA IAM role"
  type        = string
  default     = ""
  }

variable "force_destroy" {
  description = "Force destroy the S3 bucket"
  type        = bool
  default     = false
  }

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}

variable "iam_role_permissions_boundary" {
  description = "Permissions boundary to use for the IAM role"
  type        = string
  default     = ""
}

