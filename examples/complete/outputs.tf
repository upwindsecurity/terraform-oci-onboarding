output "deployment_mode" {
  description = "The deployment mode used"
  value       = module.upwind_onboarding.deployment_mode
}

output "target_compartment_ids" {
  description = "The compartments Upwind was granted access to"
  value       = module.upwind_onboarding.target_compartment_ids
}

output "vault_id" {
  description = "The OCID of the Vault holding the Upwind credentials"
  value       = module.upwind_onboarding.vault_id
}

output "upwind_management_service_account_email" {
  description = "Email of the management service account"
  value       = module.upwind_onboarding.upwind_management_service_account_email
}

output "identity_domain_oidc_issuer_url" {
  description = "OIDC issuer URL for the Identity Domain"
  value       = module.upwind_onboarding.identity_domain_oidc_issuer_url
}

output "configuration" {
  description = "Module configuration details"
  value       = module.upwind_onboarding.configuration
}
