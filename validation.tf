check "cloudscanner_credentials" {
  assert {
    condition     = !var.enable_cloudscanners || (var.scanner_client_id != "" && var.scanner_client_secret != "")
    error_message = "When enable_cloudscanners is true, both scanner_client_id and scanner_client_secret must be provided."
  }
}
