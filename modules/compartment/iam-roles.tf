### Orchestrator Compartment-Level Policies for Management Dynamic Group
###
### These policies are created at the orchestrator compartment level
### for users with only compartment-level permissions.

# Management dynamic group needs orchestrator compartment write access for deployment
resource "oci_identity_policy" "mgmt_dg_orchestrator_deploy_compute" {
  compartment_id = local.compartment_id
  name           = format("mgmt-orchestrator-compute-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to manage compute resources in orchestrator compartment"
  statements = [
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage instance-family in compartment id ${local.compartment_id}",
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage volume-family in compartment id ${local.compartment_id}",
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to read work-requests in compartment id ${local.compartment_id}"
  ]
}

resource "oci_identity_policy" "mgmt_dg_orchestrator_deploy_network" {
  compartment_id = local.compartment_id
  name           = format("mgmt-orchestrator-network-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to manage network resources in orchestrator compartment"
  statements = [
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage virtual-network-family in compartment id ${local.compartment_id}"
  ]
}

resource "oci_identity_policy" "mgmt_dg_orchestrator_deploy_functions" {
  compartment_id = local.compartment_id
  name           = format("mgmt-orchestrator-functions-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to manage functions and events in orchestrator compartment"
  statements = [
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage functions-family in compartment id ${local.compartment_id}",
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to manage cloudevents-rules in compartment id ${local.compartment_id}"
  ]
}

# Management dynamic group secret access
resource "oci_identity_policy" "mgmt_dg_secret_access_policy" {
  compartment_id = local.compartment_id
  name           = format("mgmt-secret-access-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to access secrets"
  statements     = module.iam.mgmt_secret_access_permissions
}

### Target Compartment Policies (created in each target compartment)

# Give the management dynamic group the basic viewer role on each target compartment
resource "oci_identity_policy" "upwind_management_dg_compartment_viewer_policy" {
  for_each = toset(var.target_compartment_ids)

  compartment_id = each.value
  name           = format("mgmt-compartment-viewer-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to view compartment resources"
  statements = [
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to read all-resources in compartment id ${each.value}"
  ]
}

# Grant Cloud Asset Inventory permissions on each target compartment
resource "oci_identity_policy" "upwind_management_dg_asset_viewer_policy" {
  for_each = toset(var.target_compartment_ids)

  compartment_id = each.value
  name           = format("mgmt-asset-viewer-%s", local.resource_suffix_hyphen)
  description    = "Allow management dynamic group to view assets"
  statements = [
    "Allow dynamic-group ${module.iam.upwind_management_dg.name} to read all-resources in compartment id ${each.value}"
  ]
}
