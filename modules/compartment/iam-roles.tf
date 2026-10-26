### Compartment-Mode IAM for the Management Group
###
### The orchestrator-compartment grants for the management group are NOT here.
### They are created once in modules/_shared/iam/federated-groups.tf
### (federated-mgmt-group-orchestrator-compute / -functions / -secret-access),
### which both deployment modes call, and which tenant mode has relied on alone
### in production.
###
### This file previously duplicated them as mgmt-orchestrator-{compute,network,
### functions} and mgmt-secret-access, built by re-formatting the same permission
### lists. The duplicates granted nothing the _shared policies did not already
### grant - virtual-network-family included, which is why no separate network
### policy is needed - and the compute one could not be created at all: its list
### carries "read availability-domains" and "read images", neither of which is a
### resource type OCI recognises, so CreatePolicy rejected the whole statement
### set with 400 "No permissions found" (UP-5960).
###
### Only the per-target-compartment policies below are specific to this mode.

### Target Compartment Policies (created in each target compartment)

# Give the management group the basic viewer role on each target compartment
resource "oci_identity_policy" "upwind_management_group_compartment_viewer_policy" {
  for_each = toset(var.target_compartment_ids)

  compartment_id = each.value
  name           = format("mgmt-compartment-viewer-%s-%s", local.resource_suffix_hyphen, local.target_compartment_discriminator[each.value])
  description    = "Allow management group to view compartment resources"
  freeform_tags  = local.validated_tags
  statements = [
    "Allow group id ${module.iam.federated_mgmt_group.ocid} to read all-resources in compartment id ${each.value}"
  ]
}

# Grant Cloud Asset Inventory permissions on each target compartment
resource "oci_identity_policy" "upwind_management_group_asset_viewer_policy" {
  for_each = toset(var.target_compartment_ids)

  compartment_id = each.value
  name           = format("mgmt-asset-viewer-%s-%s", local.resource_suffix_hyphen, local.target_compartment_discriminator[each.value])
  description    = "Allow management group to view assets"
  freeform_tags  = local.validated_tags
  statements = [
    "Allow group id ${module.iam.federated_mgmt_group.ocid} to read all-resources in compartment id ${each.value}"
  ]
}
