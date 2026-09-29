output "deployment_mode" {
  description = "The deployment mode used"
  value       = module.upwind_onboarding.deployment_mode
}

output "oci_tenancy_id" {
  description = "The onboarded OCI tenancy ID"
  value       = module.upwind_onboarding.oci_tenancy_id
}

output "vault_id" {
  description = "The OCID of the Vault holding the Upwind credentials"
  value       = module.upwind_onboarding.vault_id
}

output "upwind_management_service_account_email" {
  description = "Email of the management service account"
  value       = module.upwind_onboarding.upwind_management_service_account_email
}
