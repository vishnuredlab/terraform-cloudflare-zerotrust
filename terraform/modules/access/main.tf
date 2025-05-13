terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Shared application (accessible by both teams)
resource "cloudflare_zero_trust_access_application" "app" {
  account_id           = var.account_id
  name                 = var.app_name
  domain               = var.app_domain
  type                 = "self_hosted"
  session_duration     = "24h"
  app_launcher_visible = true
}

# Red Team specific application
resource "cloudflare_zero_trust_access_application" "red_team_app" {
  account_id           = var.account_id
  name                 = "Red Team - ${var.app_name}"
  domain               = "red-${var.app_domain}"
  type                 = "self_hosted"
  session_duration     = "24h"
  app_launcher_visible = true
}

# Blue Team specific application
resource "cloudflare_zero_trust_access_application" "blue_team_app" {
  account_id           = var.account_id
  name                 = "Blue Team - ${var.app_name}"
  domain               = "blue-${var.app_domain}"
  type                 = "self_hosted"
  session_duration     = "24h"
  app_launcher_visible = true
}

# Policy for email-based access to the shared app
resource "cloudflare_zero_trust_access_policy" "email_policy" {
  account_id     = var.account_id
  application_id = cloudflare_zero_trust_access_application.app.id
  name           = "Email Access Policy"
  precedence     = 2
  decision       = "allow"

  include {
    email = var.allowed_emails
  }
}

# Red team access policy for shared app using rule group
resource "cloudflare_zero_trust_access_policy" "red_team_policy" {
  account_id     = var.account_id
  application_id = cloudflare_zero_trust_access_application.app.id
  name           = "Red Team Access"
  precedence     = 1
  decision       = "allow"

  include {
    group = [var.red_team_id]
  }
  
  # Require device posture check for disk encryption
  require {
    device_posture = ["disk_encryption"]
  }
}

# Blue team access policy for shared app using rule group
resource "cloudflare_zero_trust_access_policy" "blue_team_policy" {
  account_id     = var.account_id
  application_id = cloudflare_zero_trust_access_application.app.id
  name           = "Blue Team Access"
  precedence     = 3  # Changed from 1 to 3 to make it unique
  decision       = "allow"

  include {
    group = [var.blue_team_id]
  }
  
  # Require device posture check for disk encryption
  require {
    device_posture = ["disk_encryption"]
  }
}

# Red team exclusive access policy using rule group
resource "cloudflare_zero_trust_access_policy" "red_team_exclusive_policy" {
  account_id     = var.account_id
  application_id = cloudflare_zero_trust_access_application.red_team_app.id
  name           = "Red Team Only Access"
  precedence     = 1
  decision       = "allow"

  include {
    group = [var.red_team_id]
  }
  
  # Require device posture check for disk encryption
  require {
    device_posture = ["disk_encryption"]
  }
}

# Blue team exclusive access policy using rule group
resource "cloudflare_zero_trust_access_policy" "blue_team_exclusive_policy" {
  account_id     = var.account_id
  application_id = cloudflare_zero_trust_access_application.blue_team_app.id
  name           = "Blue Team Only Access"
  precedence     = 1
  decision       = "allow"

  include {
    group = [var.blue_team_id]
  }
  
  # Require device posture check for disk encryption
  require {
    device_posture = ["disk_encryption"]
  }
}