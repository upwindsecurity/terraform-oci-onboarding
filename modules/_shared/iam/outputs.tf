### Dynamic Groups and Users

output "upwind_management_dg" {
  description = "The Upwind Management Dynamic Group details."
  value       = oci_identity_dynamic_group.upwind_management_dg
}

output "upwind_management_user" {
  description = "The Upwind Management User details."
  value       = oci_identity_user.upwind_management_user
}

output "cloudscanner_dg" {
  description = "The Cloudscanner Dynamic Group details (handles both scanning and scaling)."
  value       = var.enable_cloudscanners ? oci_identity_dynamic_group.cloudscanner_dg[0] : null
}

output "cloudscanner_user" {
  description = "The Cloudscanner User details (handles both scanning and scaling)."
  value       = var.enable_cloudscanners ? oci_identity_user.cloudscanner_user[0] : null
}

### Vault Resources

# output "vault" {
#   description = "The Vault resource details."
#   value       = oci_kms_vault.upwind_vault
# }

# output "vault_key" {
#   description = "The Vault Key resource details."
#   value       = oci_kms_key.upwind_vault_key
# }

# output "oci_vault_secret" {
#   description = "The secrets created in Vault."
#   value = {
#     upwind_client_id      = oci_vault_secret.upwind_client_id
#     upwind_client_secret  = oci_vault_secret.upwind_client_secret
#     scanner_client_id     = var.enable_cloudscanners ? oci_vault_secret.scanner_client_id[0] : null
#     scanner_client_secret = var.enable_cloudscanners ? oci_vault_secret.scanner_client_secret[0] : null
#   }
# }

### Management Dynamic Group Permissions

output "mgmt_tenancy_read_permissions" {
  description = "Management dynamic group tenancy-wide read permissions."
  value       = local.mgmt_tenancy_read_permissions_list
}

output "mgmt_orchestrator_deploy_permissions" {
  description = "Management dynamic group orchestrator compartment deployment permissions."
  value       = local.mgmt_orchestrator_deploy_permissions_list
}

output "mgmt_tenancy_iam_permissions" {
  description = "Management dynamic group tenancy-level IAM permissions."
  value       = local.mgmt_tenancy_iam_permissions_list
}

output "mgmt_secret_access_permissions" {
  description = "Management dynamic group secret access permissions."
  value       = local.mgmt_secret_access_permissions_list
}

### CloudScanner Dynamic Group Permissions

output "cloudscanner_tenancy_compute_read_permissions" {
  description = "CloudScanner dynamic group tenancy-wide compute read permissions."
  value       = local.cloudscanner_tenancy_compute_read_permissions_list
}

output "cloudscanner_tenancy_snapshot_create_permissions" {
  description = "CloudScanner dynamic group tenancy-wide snapshot creation permissions."
  value       = local.cloudscanner_tenancy_snapshot_create_permissions_list
}

output "cloudscanner_orchestrator_volume_permissions" {
  description = "CloudScanner dynamic group orchestrator compartment volume permissions."
  value       = local.cloudscanner_orchestrator_volume_permissions_list
}

output "cloudscanner_orchestrator_snapshot_delete_permissions" {
  description = "CloudScanner dynamic group orchestrator compartment snapshot deletion permissions."
  value       = local.cloudscanner_orchestrator_snapshot_delete_permissions_list
}

output "cloudscanner_orchestrator_volume_delete_permissions" {
  description = "CloudScanner dynamic group orchestrator compartment volume deletion permissions."
  value       = local.cloudscanner_orchestrator_volume_delete_permissions_list
}

output "cloudscanner_secret_access_permissions" {
  description = "CloudScanner dynamic group secret access permissions."
  value       = local.cloudscanner_secret_access_permissions_list
}

output "cloudscanner_functions_permissions" {
  description = "CloudScanner dynamic group functions permissions."
  value       = local.cloudscanner_functions_permissions_list
}

output "cloudscanner_object_storage_permissions" {
  description = "CloudScanner dynamic group object storage permissions."
  value       = local.cloudscanner_object_storage_permissions_list
}

output "cloudscanner_networking_permissions" {
  description = "CloudScanner dynamic group networking permissions."
  value       = local.cloudscanner_networking_permissions_list
}

### Tags

output "tags" {
  description = "Tags applied to all resources."
  value       = var.tags
}

output "default_tags" {
  description = "Default tags applied to all resources (can be overridden)."
  value       = var.default_tags
}

### Workload Identity Federation

output "identity_domain_federation_info" {
  description = "Information needed to configure AWS IAM OIDC provider for OCI federation"
  value = {
    identity_domain_id   = var.create_identity_domain ? try(oci_identity_domain.upwind_identity_domain[0].id, var.identity_domain_id) : var.identity_domain_id
    identity_domain_name = var.create_identity_domain ? try(oci_identity_domain.upwind_identity_domain[0].display_name, var.identity_domain_name) : var.identity_domain_name
    oidc_issuer_url = var.identity_domain_oidc_issuer_url != "" ? var.identity_domain_oidc_issuer_url : (
      # Extract base URL from IDCS endpoint and add :443 port
      # We need: https://idcs-xxx.identity.oraclecloud.com:443
      try(
        "${regex("^https://[^/]+", data.oci_identity_domain.upwind_identity_domain.url)}:443",
        ""
      )
    )
    management_user_name = oci_identity_user.upwind_management_user.name
    federated_group_name = var.aws_federated_group_name
    aws_account_id       = var.is_dev ? "437279811180" : "627244208106"
  }
  sensitive = false
}

output "identity_domain" {
  description = "The created identity domain resource (if create_identity_domain is true)"
  value       = var.create_identity_domain ? try(oci_identity_domain.upwind_identity_domain[0], null) : null
}

output "upwind_identity_domain_app_id" {
  description = "The ID of the Upwind Identity Domain OIDC client app"
  value       = oci_identity_domains_app.upwind_identity_domain_oidc_client.id
}

output "confidential_app_client_id" {
  description = "The client ID of the confidential OAuth client app for workload identity federation"
  value       = oci_identity_domains_app.upwind_identity_domain_oidc_client.name
}

output "confidential_app_client_secret" {
  description = "The client secret of the confidential OAuth client app for workload identity federation"
  value       = oci_identity_domains_app.upwind_identity_domain_oidc_client.client_secret
  sensitive   = true
}
