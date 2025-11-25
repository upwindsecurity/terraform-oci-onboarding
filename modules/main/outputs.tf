# Unified outputs that work for both deployment modes

output "deployment_mode" {
  description = "The deployment mode used (tenant or compartment)"
  value       = var.deployment_mode
}

# Workload Identity Federation Outputs (common to both modes)
output "identity_domain_federation_info" {
  description = "Information needed to configure AWS IAM OIDC provider for OCI federation"
  value       = var.deployment_mode == "tenant" ? module.tenant[0].identity_domain_federation_info : module.compartment[0].identity_domain_federation_info
}

output "identity_domain_oidc_issuer_url" {
  description = "OIDC issuer URL for the Identity Domain (for AWS IAM OIDC provider configuration)"
  value       = var.deployment_mode == "tenant" ? module.tenant[0].identity_domain_oidc_issuer_url : module.compartment[0].identity_domain_oidc_issuer_url
}

output "upwind_management_service_account_email" {
  description = "Email of the management service account"
  value       = var.deployment_mode == "tenant" ? module.tenant[0].upwind_management_service_account_email : module.compartment[0].upwind_management_service_account_email
}

# Tenant mode specific outputs
output "oci_tenancy_id" {
  description = "The OCI tenancy ID (tenant mode only)"
  value       = var.deployment_mode == "tenant" ? module.tenant[0].oci_tenancy_id : null
}

output "tenancy_details" {
  description = "Details about the OCI tenancy (tenant mode only)"
  value       = var.deployment_mode == "tenant" ? module.tenant[0].tenancy_details : null
}

# Compartment mode specific outputs
output "target_compartment_ids" {
  description = "The list of target compartment IDs (compartment mode only)"
  value       = var.deployment_mode == "compartment" ? module.compartment[0].target_compartment_ids : null
}

# Configuration output
output "configuration" {
  description = "Module configuration details"
  value       = var.deployment_mode == "tenant" ? module.tenant[0].configuration : module.compartment[0].configuration
}
