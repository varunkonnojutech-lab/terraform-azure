variable "prefix" {
  description = "Short prefix applied to all resource names (lowercase letters and numbers)."
  type        = string
  default     = "orders"
}

variable "environment" {
  description = "Environment name used in resource names and tags (e.g. dev, qa, prod)."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "sql_admin_user" {
  description = "Administrator login for the Azure SQL server."
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Administrator password for the Azure SQL server. Prefer TF_VAR_sql_admin_password or a .tfvars file over the default."
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}
