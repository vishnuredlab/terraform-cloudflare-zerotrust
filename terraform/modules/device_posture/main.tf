terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"  # Keep at version 4
    }
  }
}

# Intune integration with correct API and Auth URLs
resource "cloudflare_zero_trust_device_posture_integration" "intune_integration" {
  account_id = var.account_id
  name       = "Microsoft Intune Integration"
  type       = "intune"
  interval   = "15m"
  
  config {
    client_id         = var.intune_client_id
    client_secret     = var.intune_client_secret
    customer_id       = var.azure_tenant_id
    auth_url          = "https://login.microsoftonline.com/${var.azure_tenant_id}/oauth2/v2.0/token"
    api_url           = "https://graph.microsoft.com"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Intune Compliance Check
resource "cloudflare_zero_trust_device_posture_rule" "intune_compliance" {
  account_id  = var.account_id
  name        = "Intune Compliance Check"
  description = "Check if device is compliant according to Intune"
  type        = "intune"
  
  input {
    compliance_status = "compliant"
    connection_id     = cloudflare_zero_trust_device_posture_integration.intune_integration.id
  }

  depends_on = [cloudflare_zero_trust_device_posture_integration.intune_integration]
}

# OS Version Check with corrected version format
resource "cloudflare_zero_trust_device_posture_rule" "os_version_windows" {
  account_id  = var.account_id
  name        = "Windows OS Version Check"
  description = "Ensure Windows devices are running a supported OS version"
  type        = "os_version"
  
  match {
    platform = "windows"
  }
  
  input {
    version  = "10.0.0"  # Fixed semver format
    operator = ">="
  }
  
  depends_on = [cloudflare_zero_trust_device_posture_integration.intune_integration]
}

# Disk Encryption Check
resource "cloudflare_zero_trust_device_posture_rule" "disk_encryption" {
  account_id  = var.account_id
  name        = "Disk Encryption Check"
  description = "Ensure device disk is encrypted"
  type        = "disk_encryption"
  
  match {
    platform = "windows"
  }
  
  depends_on = [cloudflare_zero_trust_device_posture_integration.intune_integration]
}

# Firewall Check
resource "cloudflare_zero_trust_device_posture_rule" "firewall_check" {
  account_id  = var.account_id
  name        = "Firewall Status Check"
  description = "Ensure device firewall is enabled"
  type        = "firewall"
  
  match {
    platform = "windows"
  }
  
  depends_on = [cloudflare_zero_trust_device_posture_integration.intune_integration]
}