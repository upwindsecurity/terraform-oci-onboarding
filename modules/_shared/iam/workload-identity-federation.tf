locals {
  upwind_aws_account = var.is_dev ? "437279811180" : "627244208106"
  timestamp          = formatdate("YYYYMMDD-hhmm", timestamp())

  # Determine the identity domain name prefix for policy statements
  # If creating a domain, use its display_name; otherwise use the provided name
  identity_domain_name_prefix = var.create_identity_domain ? (
    try(oci_identity_domain.upwind_identity_domain[0].display_name, "") != "" ?
      "'${oci_identity_domain.upwind_identity_domain[0].display_name}'/" :
      ""
  ) : (
    var.identity_domain_name != "" ? "'${var.identity_domain_name}'/" : ""
  )
}

### Workload Identity Federation for AWS to OCI Authentication
### See: https://docs.oracle.com/en-us/iaas/Content/Identity/domains/overview.htm

# Create Identity Domain for workload identity federation
resource "oci_identity_domain" "upwind_identity_domain" {
  count          = var.create_identity_domain ? 1 : 0
  compartment_id = var.root_level_compartment_id
  display_name   = var.identity_domain_display_name != "" ? var.identity_domain_display_name : format("upwind-identity-domain-%s", local.resource_suffix_hyphen)
  description    = var.identity_domain_description
  license_type   = var.identity_domain_license_type
  home_region    = var.oci_region

  lifecycle {
    precondition {
      condition     = var.identity_domain_display_name != "" || local.resource_suffix_hyphen != ""
      error_message = "Either identity_domain_display_name must be provided or resource_suffix must be set when creating an identity domain."
    }
  }
}

# Policy to allow federated users from AWS to assume the management user role
# This enables AWS workloads to authenticate to OCI using OIDC tokens
# NOTE: The policy compartment_id uses root_level_compartment_id
# For tenant module: tenancy_id (allows "read all-resources in tenancy")
# For compartment module: orchestrator compartment_id (limited scope, cannot include tenancy-wide statements)
resource "oci_identity_policy" "aws_workload_federation_policy" {
  compartment_id = var.root_level_compartment_id
  name           = format("aws-workload-federation-%s", local.resource_suffix_hyphen)
  description    = "Allow AWS workloads to authenticate to OCI via Identity Domain OIDC federation"

  statements = concat(
    # Only include tenancy-wide read if policy is at tenancy level
    can(regex("^ocid1\\.tenancy\\..*", var.root_level_compartment_id)) ? [
      "Allow group ${local.identity_domain_name_prefix}${var.aws_federated_group_name} to read all-resources in tenancy"
    ] : [],
    # Allow federated users to deploy in orchestrator compartment
    [
      "Allow group ${local.identity_domain_name_prefix}${var.aws_federated_group_name} to manage instance-family in compartment id ${var.upwind_orchestrator_compartment_id}",
      "Allow group ${local.identity_domain_name_prefix}${var.aws_federated_group_name} to manage volume-family in compartment id ${var.upwind_orchestrator_compartment_id}",
      "Allow group ${local.identity_domain_name_prefix}${var.aws_federated_group_name} to manage virtual-network-family in compartment id ${var.upwind_orchestrator_compartment_id}",
      "Allow group ${local.identity_domain_name_prefix}${var.aws_federated_group_name} to manage functions-family in compartment id ${var.upwind_orchestrator_compartment_id}",
      # Allow access to secrets for retrieving credentials
      "Allow group ${local.identity_domain_name_prefix}${var.aws_federated_group_name} to read secrets in compartment id ${var.upwind_orchestrator_compartment_id}",
      "Allow group ${local.identity_domain_name_prefix}${var.aws_federated_group_name} to use vaults in compartment id ${var.upwind_orchestrator_compartment_id}"
    ]
  )
}
