### Tenancy-Level Policies for Management Dynamic Group
###
### These policies require tenancy-level permissions and are only created when deploying
### from the tenant module (user has tenancy-level access).
### For compartment-level deployments, see modules/compartment/iam-roles.tf

# Management dynamic group needs tenancy-wide read access for resource discovery
resource "oci_identity_policy" "mgmt_dg_tenancy_read_policy" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-tenancy-read-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to read all resources in tenancy"
  statements     = module.iam.mgmt_tenancy_read_permissions
}

# Management dynamic group needs orchestrator compartment write access for deployment
# NOTE: Must be at tenancy level to grant permissions TO the orchestrator compartment
# NOTE: Split into multiple policies to avoid OCI's "No permissions found" error
resource "oci_identity_policy" "mgmt_dg_orchestrator_deploy_compute" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-orchestrator-compute-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to manage compute resources in orchestrator compartment"
  statements = [
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage instance-family in compartment id ${local.compartment_id}",
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage volume-family in compartment id ${local.compartment_id}",
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to read work-requests in compartment id ${local.compartment_id}"
  ]
}

resource "oci_identity_policy" "mgmt_dg_orchestrator_deploy_network" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-orchestrator-network-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to manage network resources in orchestrator compartment"
  statements = [
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage virtual-network-family in compartment id ${local.compartment_id}"
  ]
}

resource "oci_identity_policy" "mgmt_dg_orchestrator_deploy_functions" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-orchestrator-functions-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to manage functions and events in orchestrator compartment"
  statements = [
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage functions-family in compartment id ${local.compartment_id}",
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage cloudevents-rules in compartment id ${local.compartment_id}"
  ]
}

# Management dynamic group tenancy-level IAM permissions (must be at tenancy level)
resource "oci_identity_policy" "mgmt_dg_tenancy_iam_policy" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-tenancy-iam-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to manage IAM resources in tenancy"
  statements     = module.iam.mgmt_tenancy_iam_permissions
}

# Management dynamic group secret access
# NOTE: Must be at tenancy level to grant permissions TO the orchestrator compartment
resource "oci_identity_policy" "mgmt_dg_secret_access_policy" {
  compartment_id = var.oci_tenancy_id
  name           = format("mgmt-secret-access-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to access secrets"
  statements     = module.iam.mgmt_secret_access_permissions
}
