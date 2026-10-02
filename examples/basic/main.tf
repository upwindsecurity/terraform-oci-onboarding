# Basic example: onboard an entire OCI tenancy to Upwind with the root module and its defaults
module "upwind_onboarding" {
  source = "../.."

  deployment_mode = "tenant"

  # Required Upwind configuration
  upwind_organization_id = var.upwind_organization_id
  upwind_client_id       = var.upwind_client_id
  upwind_client_secret   = var.upwind_client_secret

  # Required OCI configuration
  oci_tenancy_id                  = var.oci_tenancy_id
  upwind_orchestrator_compartment = var.upwind_orchestrator_compartment
}
