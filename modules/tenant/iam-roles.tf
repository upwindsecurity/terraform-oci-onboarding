### Tenancy-Level Policies for Management Group
###
### These policies require tenancy-level permissions and are only created when deploying
### from the tenant module (user has tenancy-level access).
### For compartment-level deployments, see modules/compartment/iam-roles.tf

# Management group needs tenancy-wide read access for resource discovery
resource "oci_identity_policy" "mgmt_group_tenancy_read_policy" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-tenancy-read-%s", local.resource_suffix_hyphen)
  description    = "Allow management group to read all resources in tenancy"
  statements     = module.iam.federated_mgmt_group_tenancy_read_permissions
}

# Management group needs orchestrator compartment write access for deployment
# NOTE: Must be at tenancy level to grant permissions TO the orchestrator compartment
# NOTE: Split into multiple policies to avoid OCI's "No permissions found" error
resource "oci_identity_policy" "mgmt_group_orchestrator_deploy_compute" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-orchestrator-compute-%s", local.resource_suffix_hyphen)
  description    = "Allow management group to manage compute resources in orchestrator compartment"
  statements = [
    for perm in module.iam.federated_mgmt_group_orchestrator_deploy_compute_permissions :
    format(perm, local.compartment_id)
  ]
}

resource "oci_identity_policy" "mgmt_group_orchestrator_deploy_network" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-orchestrator-network-%s", local.resource_suffix_hyphen)
  description    = "Allow management group to manage network resources in orchestrator compartment"
  statements = [
    for perm in module.iam.federated_mgmt_group_orchestrator_deploy_network_permissions :
    format(perm, local.compartment_id)
  ]
}

resource "oci_identity_policy" "mgmt_group_orchestrator_deploy_functions" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-orchestrator-functions-%s", local.resource_suffix_hyphen)
  description    = "Allow management group to manage functions and events in orchestrator compartment"
  statements = [
    for perm in module.iam.federated_mgmt_group_orchestrator_deploy_functions_permissions :
    format(perm, local.compartment_id)
  ]
}

# Management group tenancy-level IAM permissions (must be at tenancy level)
resource "oci_identity_policy" "mgmt_group_tenancy_iam_policy" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-tenancy-iam-%s", local.resource_suffix_hyphen)
  description    = "Allow management group to manage IAM resources in tenancy"
  statements     = module.iam.federated_mgmt_group_tenancy_iam_permissions
}

# Management group secret access
# NOTE: Must be at tenancy level to grant permissions TO the orchestrator compartment
resource "oci_identity_policy" "mgmt_group_secret_access_policy" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-secret-access-%s", local.resource_suffix_hyphen)
  description    = "Allow management group to access secrets"
  statements     = module.iam.federated_mgmt_group_secret_access_permissions
}
