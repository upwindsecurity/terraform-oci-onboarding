### Shared IAM Module Outputs

output "iam_module" {
  description = "The shared IAM module outputs."
  value       = module.iam
}

### Orchestrator Compartment Policies

output "mgmt_dg_orchestrator_deploy_compute" {
  description = "Management dynamic group orchestrator compartment compute deployment policy."
  value       = oci_identity_policy.mgmt_dg_orchestrator_deploy_compute
}

output "mgmt_dg_orchestrator_deploy_network" {
  description = "Management dynamic group orchestrator compartment network deployment policy."
  value       = oci_identity_policy.mgmt_dg_orchestrator_deploy_network
}

output "mgmt_dg_orchestrator_deploy_functions" {
  description = "Management dynamic group orchestrator compartment functions deployment policy."
  value       = oci_identity_policy.mgmt_dg_orchestrator_deploy_functions
}

output "mgmt_dg_secret_access_policy" {
  description = "Management dynamic group secret access policy."
  value       = oci_identity_policy.mgmt_dg_secret_access_policy
}

### Target Compartment Policies

output "upwind_management_dg_compartment_viewer_policies" {
  description = "The compartment viewer policies for the management dynamic group (one per target compartment)."
  value       = oci_identity_policy.upwind_management_dg_compartment_viewer_policy
}

output "upwind_management_dg_asset_viewer_policies" {
  description = "The asset viewer policies for the management dynamic group (one per target compartment)."
  value       = oci_identity_policy.upwind_management_dg_asset_viewer_policy
}

### CloudScanner Orchestrator Compartment Policies

output "cs_dg_secret_access_policy" {
  description = "CloudScanner dynamic group secret access policy."
  value       = var.enable_cloudscanners ? oci_identity_policy.cs_dg_secret_access_policy[0] : null
}

output "cs_dg_functions_policy" {
  description = "CloudScanner dynamic group functions policy."
  value       = var.enable_cloudscanners ? oci_identity_policy.cs_dg_functions_policy[0] : null
}

output "cs_dg_object_storage_policy" {
  description = "CloudScanner dynamic group object storage policy."
  value       = var.enable_cloudscanners ? oci_identity_policy.cs_dg_object_storage_policy[0] : null
}

output "cs_dg_networking_policy" {
  description = "CloudScanner dynamic group networking policy."
  value       = var.enable_cloudscanners ? oci_identity_policy.cs_dg_networking_policy[0] : null
}

### CloudScanner Target Compartment Policies

output "upwind_cloudscanner_dg_compute_viewer_policies" {
  description = "The compute viewer policies for CloudScanner dynamic group (one per target compartment)."
  value       = var.enable_cloudscanners ? oci_identity_policy.upwind_cloudscanner_dg_compute_viewer_policy : {}
}

### Workload Identity Federation

output "identity_domain_id" {
  description = "The ID of the OCI Identity Domain."
  value       = module.iam.identity_domain.id
}

output "identity_domain_name" {
  description = "The name of the OCI Identity Domain."
  value       = module.iam.identity_domain.name
}

output "identity_domain_federation_info" {
  description = "Information needed to configure AWS IAM OIDC provider for OCI federation"
  value       = module.iam.identity_domain_federation_info
}

output "identity_domain_oidc_issuer_url" {
  description = "OIDC issuer URL for the Identity Domain (for AWS IAM OIDC provider configuration)"
  value       = module.iam.identity_domain_federation_info.oidc_issuer_url
}

output "upwind_management_service_account_email" {
  description = "Email of the management service account"
  value       = module.iam.upwind_management_user.email
}

### Target Compartments

output "target_compartment_ids" {
  description = "The list of target compartment IDs."
  value       = var.target_compartment_ids
}

### Configuration

output "configuration" {
  description = "Module configuration details."
  value = {
    upwind_organization_id           = var.upwind_organization_id
    upwind_orchestrator_compartment_id = var.upwind_orchestrator_compartment_id
    oci_region                       = var.oci_region
    enable_cloudscanners             = var.enable_cloudscanners
    enable_dspm_scanning             = var.enable_dspm_scanning
    resource_suffix                  = var.resource_suffix
    tags                             = var.tags
  }
}
