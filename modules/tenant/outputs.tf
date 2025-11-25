### Tenancy Information

output "oci_tenancy_id" {
  description = "The OCI tenancy ID."
  value       = var.oci_tenancy_id
}

output "tenancy_details" {
  description = "Details about the OCI tenancy."
  value       = data.oci_identity_tenancy.tenancy
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

### Configuration

output "configuration" {
  description = "Module configuration details."
  value = {
    upwind_organization_id          = var.upwind_organization_id
    upwind_orchestrator_compartment = var.upwind_orchestrator_compartment
    oci_region                      = var.oci_region
    oci_tenancy_id                  = var.oci_tenancy_id
    enable_cloudscanners            = var.enable_cloudscanners
    enable_dspm_scanning            = var.enable_dspm_scanning
    resource_suffix                 = var.resource_suffix
    tags                            = var.tags
  }
}
