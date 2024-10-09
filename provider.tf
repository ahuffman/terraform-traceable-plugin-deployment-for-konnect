terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
    }
  }
}

provider "konnect" {
  personal_access_token = "${var.konnect_personal_access_token}"
  server_url            = "${var.konnect_api_url}"
}