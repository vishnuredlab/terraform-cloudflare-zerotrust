variable "cloudflare_api_key" {
  description = "Cloudflare Global API Key"
  type        = string
}

variable "cloudflare_email" {
  description = "Cloudflare account email"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}


variable "azure_client_id" {
  description = "Azure AD Client ID"
  type        = string
}

variable "azure_client_secret" {
  description = "Azure AD Client Secret"
  type        = string
  sensitive   = true
}

variable "azure_directory_id" {
  description = "Azure AD Directory ID (Tenant ID)"
  type        = string
}