locals {
  # Define permission strings with direct dynamic group names and scope placeholders
  # Format: ${var.upwind_orchestrator_compartment_id} = compartment or tenancy scope placeholder

  # CloudScanner Dynamic Group Permissions
  # Tenancy-wide compute resource read access
  cloudscanner_tenancy_compute_read_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read instances in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read boot-volumes in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read block-volumes in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read instance-configurations in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read instance-pools in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read work-requests in tenancy"
  ] : []

  # Tenancy-wide container registry read, for pulling images to scan (UP-6615).
  # OCIR advertises a Docker v2 bearer challenge whose token realm accepts OCI
  # request signing, so the scanner mints a short-lived registry token as its
  # instance principal rather than carrying a static user/auth-token pair. This
  # grant is what authorises that exchange; without it the mint is refused and the
  # scanner falls back to DOCKER_USER/DOCKER_PASSWORD.
  #
  # Tenancy rather than compartment scope: OCIR repositories live in whichever
  # compartment they were created in, and the images a scanner is asked to pull
  # can be spread across several.
  cloudscanner_tenancy_registry_read_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read repos in tenancy"
  ] : []

  # Tenancy-wide snapshot creation permissions
  cloudscanner_tenancy_snapshot_create_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage volume-family in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage boot-volume-backups in tenancy",
    # Required to create snapshots in tenancies that apply defined-tag defaults
    # (e.g. Oracle-Tags.CreatedBy) to new resources: without permission to use
    # the tag namespace, OCI rejects the backup with "Invalid tags". Tag
    # namespaces live in the root compartment, so this must be tenancy-scoped.
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to use tag-namespaces in tenancy",
  ] : []

  # Cloudscanner kms permissions for encrypted volumes
  cloudscanner_tenancy_kms_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to use key-delegate in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to use keys in tenancy",
    "Allow service blockstorage to use keys in tenancy",
  ] : []

  # Compartment-scoped KMS permissions for single-account encrypted volume restore
  cloudscanner_compartment_kms_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to use key-delegate in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to use keys in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow service blockstorage to use keys in compartment id ${var.upwind_orchestrator_compartment_id}",
  ] : []

  # Orchestrator compartment volume management permissions
  cloudscanner_orchestrator_volume_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read block-volumes in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read boot-volumes in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage instances in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage instance-pools in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage instance-configurations in compartment id ${var.upwind_orchestrator_compartment_id}"
  ] : []

  # Orchestrator compartment volume deletion with conditions
  cloudscanner_orchestrator_volume_delete_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage block-volumes in compartment id ${var.upwind_orchestrator_compartment_id} where target.block-volume.name = /vol-*/",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage boot-volumes in compartment id ${var.upwind_orchestrator_compartment_id} where target.boot-volume.name = /vol-*/"
  ] : []

  # CloudScanner secret access
  cloudscanner_secret_access_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read secrets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to use vaults in compartment id ${var.upwind_orchestrator_compartment_id}"
  ] : []

  # CloudScanner functions permissions
  cloudscanner_functions_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage functions-family in compartment id ${var.upwind_orchestrator_compartment_id}"
  ] : []

  # CloudScanner object storage permissions
  cloudscanner_object_storage_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read buckets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to read objects in compartment id ${var.upwind_orchestrator_compartment_id}",
  ] : []

  # CloudScanner networking permissions for scaling
  cloudscanner_networking_permissions_list = var.enable_cloudscanners ? [
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage subnets in compartment id ${var.upwind_orchestrator_compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to use subnets in compartment id ${var.upwind_orchestrator_compartment_id}"
  ] : []
}
