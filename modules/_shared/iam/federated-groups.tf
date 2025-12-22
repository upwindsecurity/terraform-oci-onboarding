### IAM Group for Workload Identity Federation
###
### Identity Domain users authenticated via WIF must be members of a group
### Policies grant permissions to the group, not individual users

# Create an Identity Domain group for federated management users
resource "oci_identity_domains_group" "upwind_federated_mgmt_group" {
  idcs_endpoint = data.oci_identity_domain.upwind_identity_domain.url
  display_name  = format("upwind-federated-mgmt-%s", local.resource_suffix_hyphen)
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:Group"]

  members {
    type  = "User"
    value = oci_identity_domains_user.upwind_management_user.id
  }

  depends_on = [
    oci_identity_domains_user.upwind_management_user
  ]
}

# Create an Identity Domain group for federated reader users
resource "oci_identity_domains_group" "upwind_federated_reader_group" {
  idcs_endpoint = data.oci_identity_domain.upwind_identity_domain.url
  display_name  = format("upwind-federated-reader-%s", local.resource_suffix_hyphen)
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:Group"]

  members {
    type  = "User"
    value = oci_identity_domains_user.upwind_ro_user.id
  }

  depends_on = [
    oci_identity_domains_user.upwind_ro_user
  ]
}

locals {
  # Group permission lists mirror the dynamic group permissions but use "group" instead of "dynamic-group"
  # These permissions allow WIF-authenticated users (via group membership) to deploy into the orchestrator compartment

  # Federated management group orchestrator compartment deployment permissions
  # Split into separate lists for compute, network, and functions to match tenant/compartment module structure
  federated_mgmt_group_orchestrator_deploy_compute_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-configurations in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-family in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage volume-family in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read work-requests in compartment id %s"
  ]

  federated_mgmt_group_orchestrator_deploy_network_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage virtual-network-family in compartment id %s"
  ]

  federated_mgmt_group_orchestrator_deploy_functions_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage functions-family in compartment id %s",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage cloudevents-rules in compartment id %s"
  ]

  # Combined list for backward compatibility (used by federated-groups.tf policies)
  federated_mgmt_group_orchestrator_deploy_permissions_list = [
    # Compartment inspection (required to access the compartment)
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to inspect compartments in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read compartments in compartment id ${var.upwind_orchestrator_compartment_id}",
    # Compute Instance resource creation permissions
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-configurations in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-pools in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instances in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage block-volumes in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage availability-domains in compartment id ${var.upwind_orchestrator_compartment_id}",
    # Required to reference images and subnets in instance configurations
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read instance-images in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use subnets in compartment id ${var.upwind_orchestrator_compartment_id}",
    # Networking resource creation permissions
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage virtual-networks in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage subnets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage route-tables in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage security-lists in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage internet-gateways in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage nat-gateways in compartment id ${var.upwind_orchestrator_compartment_id}",
    # Functions creation permissions
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage functions in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage function-applications in compartment id ${var.upwind_orchestrator_compartment_id}",
    # Events and rules creation permissions
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage events in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage rules in compartment id ${var.upwind_orchestrator_compartment_id}",
    # Required for Terraform to check operation status
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read work-requests in compartment id ${var.upwind_orchestrator_compartment_id}",
    # Required basic service usage
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use service-gateways in compartment id ${var.upwind_orchestrator_compartment_id}"
  ]

  # Federated management group tenancy-wide read permissions (only if at tenancy level)
  federated_mgmt_group_tenancy_read_permissions_list = can(regex("^ocid1\\.tenancy\\..*", var.root_level_compartment_id)) ? [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read all-resources in tenancy",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to inspect compartments in tenancy",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to inspect instance-images in tenancy",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-images in tenancy"
  ] : []

  # Federated management group tenancy-level IAM permissions (only if at tenancy level)
  federated_mgmt_group_tenancy_iam_permissions_list = can(regex("^ocid1\\.tenancy\\..*", var.root_level_compartment_id)) ? [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage policies in tenancy",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage dynamic-groups in tenancy",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage users in tenancy"
  ] : []

  # Federated management group secret access for deployment
  federated_mgmt_group_secret_access_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage secrets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read secrets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use vaults in compartment id ${var.upwind_orchestrator_compartment_id}"
  ]

  # Federated reader group tenancy-wide read permissions
  # Includes inspect compartments to allow access to compartments, and explicit instance-family read
  # to ensure ListInstances operations work correctly
  federated_reader_group_tenancy_read_permissions_list = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_reader_group.ocid} to read all-resources in tenancy",
    "Allow group id ${oci_identity_domains_group.upwind_federated_reader_group.ocid} to inspect compartments in tenancy",
    "Allow group id ${oci_identity_domains_group.upwind_federated_reader_group.ocid} to read instance-family in tenancy",
    "Allow group id ${oci_identity_domains_group.upwind_federated_reader_group.ocid} to read instance-images in tenancy",
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
}

# Federated management group needs orchestrator compartment deployment permissions
# Split into multiple policies to match dynamic group structure and avoid OCI errors
resource "oci_identity_policy" "federated_mgmt_group_orchestrator_deploy_compute" {
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-orchestrator-compute-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to manage compute resources in orchestrator compartment"
  statements = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use compartments in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage auto-scaling-configurations in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage compute-capacity-reservations in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage compute-global-image-capability-schema in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage compute-image-capability-schema in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage dedicated-vm-hosts in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-configurations in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-family in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-images in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instance-pools in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage instances in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage volume-family in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage volumes in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read work-requests in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage vcns in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage vnics in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage subnets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage virtual-network-family in compartment id ${var.upwind_orchestrator_compartment_id}"
  ]
}

resource "oci_identity_policy" "federated_mgmt_group_orchestrator_deploy_network" {
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-orchestrator-network-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to manage network resources in orchestrator compartment"
  statements = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use compartments in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use subnets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage vcns in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage virtual-network-family in compartment id ${var.upwind_orchestrator_compartment_id}"
  ]
}

resource "oci_identity_policy" "federated_mgmt_group_orchestrator_deploy_functions" {
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-orchestrator-functions-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to manage functions and events in orchestrator compartment"
  statements = [
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to use compartments in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage functions-family in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage cloudevents-rules in compartment id ${var.upwind_orchestrator_compartment_id}"
  ]
}

# Federated management group tenancy-level IAM permissions (tenant mode only)
resource "oci_identity_policy" "federated_mgmt_group_tenancy_iam_policy" {
  count          = can(regex("^ocid1\\.tenancy\\..*", var.root_level_compartment_id)) ? 1 : 0
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-tenancy-iam-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to manage IAM resources in tenancy"
  statements     = local.federated_mgmt_group_tenancy_iam_permissions_list
}

# Federated management group secret access
resource "oci_identity_policy" "federated_mgmt_group_secret_access_policy" {
  compartment_id = var.root_level_compartment_id
  name           = format("federated-mgmt-group-secret-access-%s", local.resource_suffix_hyphen)
  description    = "Allow federated management group to access secrets"
  statements     = local.federated_mgmt_group_secret_access_permissions_list
}

# Federated reader group tenancy-wide read access (tenant mode only)
resource "oci_identity_policy" "federated_reader_group_tenancy_read_policy" {
  count          = can(regex("^ocid1\\.tenancy\\..*", var.root_level_compartment_id)) ? 1 : 0
  compartment_id = var.root_level_compartment_id
  name           = format("federated-reader-group-tenancy-read-%s", local.resource_suffix_hyphen)
  description    = "Allow federated reader group to read all resources in tenancy"
  statements     = local.federated_reader_group_tenancy_read_permissions_list
}

