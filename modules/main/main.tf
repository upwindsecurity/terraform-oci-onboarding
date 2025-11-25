# Tenant deployment mode
module "tenant" {
  count  = var.deployment_mode == "tenant" ? 1 : 0
  source = "../tenant"

  # Upwind Configuration
  upwind_organization_id = var.upwind_organization_id
  upwind_client_id       = var.upwind_client_id
  upwind_client_secret   = var.upwind_client_secret
  scanner_client_id      = var.scanner_client_id
  scanner_client_secret  = var.scanner_client_secret
  resource_suffix        = var.resource_suffix
  enable_cloudscanners   = var.enable_cloudscanners
  is_dev                 = var.is_dev
  tags                   = var.tags

  # OCI Configuration
  oci_region                      = var.oci_region
  oci_tenancy_id                  = var.oci_tenancy_id
  upwind_orchestrator_compartment = var.upwind_orchestrator_compartment
  enable_dspm_scanning            = var.enable_dspm_scanning

  # Workload Identity Federation Configuration
  root_level_compartment_id       = var.root_level_compartment_id != "" ? var.root_level_compartment_id : var.oci_tenancy_id
  create_identity_domain          = var.create_identity_domain
  identity_domain_id              = var.identity_domain_id
  identity_domain_display_name    = var.identity_domain_display_name
  identity_domain_description     = var.identity_domain_description
  identity_domain_license_type    = var.identity_domain_license_type
  identity_domain_name            = var.identity_domain_name
  identity_domain_oidc_issuer_url = var.identity_domain_oidc_issuer_url
  aws_federated_group_name        = var.aws_federated_group_name
}

# Compartment deployment mode
module "compartment" {
  count  = var.deployment_mode == "compartment" ? 1 : 0
  source = "../compartment"

  # Upwind Configuration
  upwind_organization_id = var.upwind_organization_id
  upwind_client_id       = var.upwind_client_id
  upwind_client_secret   = var.upwind_client_secret
  scanner_client_id      = var.scanner_client_id
  scanner_client_secret  = var.scanner_client_secret
  resource_suffix        = var.resource_suffix
  enable_cloudscanners   = var.enable_cloudscanners
  is_dev                 = var.is_dev
  tags                   = var.tags

  # OCI Configuration
  oci_region                         = var.oci_region
  oci_tenancy_id                     = var.oci_tenancy_id
  upwind_orchestrator_compartment_id = var.upwind_orchestrator_compartment_id
  target_compartment_ids             = var.target_compartment_ids
  enable_dspm_scanning               = var.enable_dspm_scanning

  # Workload Identity Federation Configuration
  root_level_compartment_id       = var.root_level_compartment_id != "" ? var.root_level_compartment_id : var.upwind_orchestrator_compartment_id
  create_identity_domain          = var.create_identity_domain
  identity_domain_id              = var.identity_domain_id
  identity_domain_display_name    = var.identity_domain_display_name
  identity_domain_description     = var.identity_domain_description
  identity_domain_license_type    = var.identity_domain_license_type
  identity_domain_name            = var.identity_domain_name
  identity_domain_oidc_issuer_url = var.identity_domain_oidc_issuer_url
  aws_federated_group_name        = var.aws_federated_group_name
}
