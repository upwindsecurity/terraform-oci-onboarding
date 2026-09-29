# Complete example: onboard selected OCI compartments to Upwind with the root module, CloudScanners and DSPM scanning
module "upwind_onboarding" {
  source = "../.."

  deployment_mode        = "compartment"
  target_compartment_ids = var.target_compartment_ids

  # Required Upwind configuration
  upwind_organization_id = var.upwind_organization_id
  upwind_client_id       = var.upwind_client_id
  upwind_client_secret   = var.upwind_client_secret
  upwind_region          = var.upwind_region

  # Required OCI configuration
  oci_tenancy_id                     = var.oci_tenancy_id
  oci_region                         = var.oci_region
  upwind_orchestrator_compartment_id = var.upwind_orchestrator_compartment_id

  # CloudScanners
  enable_cloudscanners  = true
  scanner_client_id     = var.scanner_client_id
  scanner_client_secret = var.scanner_client_secret
  enable_dspm_scanning  = true

  # Naming and tags
  resource_suffix = var.resource_suffix
  tags            = var.tags
}
