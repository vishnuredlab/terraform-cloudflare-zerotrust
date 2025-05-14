terraform {
  cloud {
    organization = "reddome_academy"
    workspaces {
      name = "cloudflare-zerotrust-dev"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_key   = var.cloudflare_api_key
  email     = var.cloudflare_email
  account_id = var.cloudflare_account_id
}

module "warp" {
  source = "../../modules/warp"
  account_id = var.account_id
  warp_name  = "Dev WARP Configuration"
}

resource "cloudflare_zero_trust_access_identity_provider" "azure_ad" {
  account_id = var.account_id
  name       = "Azure AD"
  type       = "azureAD"
  config {
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
    directory_id  = var.azure_directory_id
  }
}