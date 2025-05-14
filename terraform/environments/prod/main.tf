terraform {
  cloud {
    organization = "REDDOMELAB"
    workspaces {
      name = "terraform-cloudflare-zerotrust"
    }
  }

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.4.0"
  }
}

provider "cloudflare" {
  api_token = "kL7lFTOLBiGlgslxW4tADvbMJvhbXJDg_yXQ9ldg"
  retries   = 3
}

# Global Zero Trust configuration
resource "cloudflare_zero_trust_gateway_settings" "zero_trust" {
  account_id = "7cddccd98a674da8afe19d066889da04"
}

module "idp" {
  source = "../../modules/idp"
  account_id          = var.account_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_directory_id  = var.azure_directory_id
  red_team_name       = var.red_team_name
  red_team_group_ids  = var.red_team_group_ids
  blue_team_name      = var.blue_team_name
  blue_team_group_ids = var.blue_team_group_ids
  depends_on = [cloudflare_zero_trust_gateway_settings.zero_trust]
}

module "device_posture" {
  source = "../../modules/device_posture"
  account_id = var.account_id
  intune_client_id = var.intune_client_id
  intune_client_secret = var.intune_client_secret
  azure_tenant_id = var.azure_directory_id
  depends_on = [cloudflare_zero_trust_gateway_settings.zero_trust]
}

module "warp" {
  source = "../../modules/warp"
  account_id = var.account_id
  warp_name  = "WARP-${terraform.workspace}"
  azure_ad_provider_id = module.idp.entra_idp_id
  security_teams_id = module.idp.red_team_id
  azure_group_ids = concat(var.red_team_group_ids, var.blue_team_group_ids)
  red_team_name = var.red_team_name
  blue_team_name = var.blue_team_name
  red_team_group_ids = var.red_team_group_ids
  blue_team_group_ids = var.blue_team_group_ids
  enable_logs = var.enable_logs
  azure_storage_account = var.azure_storage_account
  azure_storage_container = var.azure_storage_container
  azure_sas_token = var.azure_sas_token
  depends_on = [cloudflare_zero_trust_gateway_settings.zero_trust, module.idp]
}

module "gateway" {
  source = "../../modules/gateway"
  account_id    = var.account_id
  location_name = "Gateway-${terraform.workspace}"
  networks      = ["192.168.1.0/24"]
  depends_on    = [cloudflare_zero_trust_gateway_settings.zero_trust]
}

module "access" {
  source = "../../modules/access"
  account_id     = var.account_id
  app_name       = "gvolt-${terraform.workspace}"
  app_domain     = "app-${terraform.workspace}.gvolt.co.uk"
  allowed_emails = ["user@gvolt.co.uk"]
  red_team_name  = var.red_team_name
  blue_team_name = var.blue_team_name
  red_team_id    = module.idp.red_team_id
  blue_team_id   = module.idp.blue_team_id
  red_team_group_ids = var.red_team_group_ids
  blue_team_group_ids = var.blue_team_group_ids
  device_posture_rule_ids = [
    module.device_posture.disk_encryption_rule_id,
    module.device_posture.os_version_rule_id,
    module.device_posture.intune_compliance_rule_id
  ]
  depends_on     = [cloudflare_zero_trust_gateway_settings.zero_trust, module.device_posture, module.idp]
}