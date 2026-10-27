### IAM Group for Workload Identity Federation
###
### Identity Domain users authenticated via WIF must be members of a group
### Policies grant permissions to the group, not individual users

# Create an Identity Domain group for federated management users
resource "oci_identity_domains_group" "upwind_federated_mgmt_group" {
  idcs_endpoint = local.identity_domain_url
  display_name  = format("upwind-federated-mgmt-%s", local.resource_suffix_hyphen)
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:Group",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
  ]

  members {
    type  = "User"
    value = oci_identity_domains_user.upwind_management_user.id
  }

  urnietfparamsscimschemasoracleidcsextension_oci_tags {
    dynamic "freeform_tags" {
      for_each = local.validated_tags
      content {
        key   = freeform_tags.key
        value = freeform_tags.value
      }
    }

    dynamic "defined_tags" {
      for_each = local.validated_defined_tags
      content {
        namespace = split(".", defined_tags.key)[0]
        key       = split(".", defined_tags.key)[1]
        value     = defined_tags.value
      }
    }
  }

  depends_on = [
    oci_identity_domains_user.upwind_management_user
  ]
}

# Create an Identity Domain group for federated reader users
resource "oci_identity_domains_group" "upwind_federated_reader_group" {
  idcs_endpoint = local.identity_domain_url
  display_name  = format("upwind-federated-reader-%s", local.resource_suffix_hyphen)
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:Group",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
  ]

  members {
    type  = "User"
    value = oci_identity_domains_user.upwind_ro_user.id
  }

  urnietfparamsscimschemasoracleidcsextension_oci_tags {
    dynamic "freeform_tags" {
      for_each = local.validated_tags
      content {
        key   = freeform_tags.key
        value = freeform_tags.value
      }
    }

    dynamic "defined_tags" {
      for_each = local.validated_defined_tags
      content {
        namespace = split(".", defined_tags.key)[0]
        key       = split(".", defined_tags.key)[1]
        value     = defined_tags.value
      }
    }
  }

  depends_on = [
    oci_identity_domains_user.upwind_ro_user
  ]
}

locals {
  # Keeps object contents and secret values out of "read all-resources".
  read_all_resources_content_exclusion = "where all {request.permission != 'OBJECT_READ', request.permission != 'SECRET_BUNDLE_READ'}"

  # Group permission lists mirror the dynamic group permissions but use "group" instead of "dynamic-group"
  # These permissions allow WIF-authenticated users (via group membership) to deploy into the orchestrator compartment

  # Federated management group orchestrator compartment deployment permissions
  # Split into separate lists for compute, network, and functions to match tenant/compartment module structure
  federated_mgmt_group_orchestrator_deploy_compute_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-configurations in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-family in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage volume-family in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read work-requests in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read availability-domains in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read images in compartment id %s"
  ]

  federated_mgmt_group_orchestrator_deploy_network_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage virtual-network-family in compartment id %s"
  ]

  federated_mgmt_group_orchestrator_deploy_functions_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage functions-family in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage cloudevents-rules in compartment id %s"
  ]

  # Federated management group tenancy-wide read permissions (only if at tenancy level)
  federated_mgmt_group_tenancy_read_permissions_list = can(regex("^ocid1\\.tenancy\\..*", var.root_level_compartment_id)) ? [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read all-resources in tenancy ${local.read_all_resources_content_exclusion}",
  ] : []

  # Federated management group secret access for deployment
  federated_mgmt_group_secret_access_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage secrets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read secrets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use vaults in compartment id ${var.upwind_orchestrator_compartment_id}",
    # The CloudScanner deployment reads its credentials from the vault.
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read secret-bundles in compartment id ${var.upwind_orchestrator_compartment_id}"
  ]

  # Federated reader group tenancy-wide read permissions
  federated_reader_group_tenancy_read_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_reader_group.ocid} to read all-resources in tenancy ${local.read_all_resources_content_exclusion}",
  ]

}

### Policies for Federated Management Group Deployment Permissions
### NOTE: These policies are created at the root_level_compartment_id level
### (tenancy for tenant mode, orchestrator compartment for compartment mode)

# Federated management group needs tenancy-wide read access for resource discovery (tenant mode only)
resource "oci_identity_policy" "federated_mgmt_group_tenancy_read_policy" {
  count          = can(regex("^ocid1\\.tenancy\\..*", var.root_level_compartment_id)) ? 1 : 0
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-tenancy-read-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to read all resources in tenancy"
  statements     = local.federated_mgmt_group_tenancy_read_permissions_list
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

# Federated management group needs orchestrator compartment deployment permissions
# Split into multiple policies to match dynamic group structure and avoid OCI errors.
# OCI caps a tenancy at 500 policy statements, so no statement repeats one that an
# aggregate family (instance-family, volume-family, virtual-network-family) already grants.
resource "oci_identity_policy" "federated_mgmt_group_orchestrator_deploy_compute" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-orchestrator-compute-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to manage compute resources in orchestrator compartment"
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
  statements = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use compartments in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage auto-scaling-configurations in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-configurations in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-family in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-pools in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage volume-family in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read work-requests in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage virtual-network-family in compartment id ${var.upwind_orchestrator_compartment_id}"
  ]

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

resource "oci_identity_policy" "federated_mgmt_group_orchestrator_deploy_functions" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-orchestrator-functions-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to manage functions and events in orchestrator compartment"
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
  statements = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage functions-family in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage cloudevents-rules in compartment id ${var.upwind_orchestrator_compartment_id}"
  ]

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

moved {
  from = oci_identity_policy.federated_mgmt_group_orchestrator_deploy_compute
  to   = oci_identity_policy.federated_mgmt_group_orchestrator_deploy_compute[0]
}

moved {
  from = oci_identity_policy.federated_mgmt_group_orchestrator_deploy_functions
  to   = oci_identity_policy.federated_mgmt_group_orchestrator_deploy_functions[0]
}

# Federated management group secret access
resource "oci_identity_policy" "federated_mgmt_group_secret_access_policy" {
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-secret-access-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to access secrets"
  statements     = local.federated_mgmt_group_secret_access_permissions_list
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

# Federated reader group tenancy-wide read access (tenant mode only)
resource "oci_identity_policy" "federated_reader_group_tenancy_read_policy" {
  count          = can(regex("^ocid1\\.tenancy\\..*", var.root_level_compartment_id)) ? 1 : 0
  compartment_id = var.root_level_compartment_id
  name           = format("federated-reader-group-tenancy-read-%s", local.resource_suffix_hyphen)
  description    = "Allow federated reader group to read all resources in tenancy"
  statements     = local.federated_reader_group_tenancy_read_permissions_list
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags

  lifecycle {
    # OCI's tag defaults add these after create; without this every plan would strip them.
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

