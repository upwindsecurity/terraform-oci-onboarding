check "cloudscanner_credentials_required" {
  assert {
    condition     = !var.enable_cloudscanners || (var.scanner_client_id != "" && var.scanner_client_secret != "")
    error_message = "When enable_cloudscanners is true, both scanner_client_id and scanner_client_secret must be provided."
  }
}

check "cloudscanner_credentials_not_allowed" {
  assert {
    condition     = var.enable_cloudscanners || (var.scanner_client_id == "" && var.scanner_client_secret == "")
    error_message = "When enable_cloudscanners is false, scanner_client_id and scanner_client_secret must be empty."
  }
}
