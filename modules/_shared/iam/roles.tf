### Orchestrator Compartment-Level Policies
###
### These policies are created at the orchestrator compartment level and can be used by
### both tenant (tenancy-level) and compartment (compartment-level) deployments.
###
### NOTE: Tenancy-level policies are in modules/tenant/iam-roles.tf and
### modules/tenant/iam-roles-cloudscanner.tf because they require tenancy-level permissions.

### CloudScanner Orchestrator Compartment Policies

# CloudScanner restores, attaches and deletes its scan volumes in the orchestrator compartment
resource "oci_identity_policy" "cs_dg_orchestrator_volume_policy" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = var.upwind_orchestrator_compartment_id
  name           = format("cs-orchestrator-volume-%s", local.resource_suffix_hyphen)
  description    = "Allow cloudscanner dynamic group to manage volumes in orchestrator compartment"
  statements     = local.cloudscanner_orchestrator_volume_permissions_list
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
}
