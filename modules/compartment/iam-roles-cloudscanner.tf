### Orchestrator Compartment-Level Policies for CloudScanner Dynamic Group
###
### These policies are created at the orchestrator compartment level
### for users with only compartment-level permissions.
###
### NOTE: Volume and snapshot deletion policies are in modules/_shared/iam/roles.tf
###
### NOTE: If the tenancy applies defined-tag defaults (e.g. Oracle-Tags.CreatedBy)
### to new resources, the CloudScanner dynamic group also needs
### "use tag-namespaces in tenancy" or snapshot creation fails with
### "Invalid tags". Tag namespaces live in the root compartment, so that grant
### cannot be created from a compartment-scoped deployment — a tenancy admin
### must add it separately. The tenant module grants it via
### cs-tenancy-snapshot-create (modules/_shared/iam/permissions.tf).

### NOTE: Pulling images from OCIR needs "read repos in tenancy" so the scanner's
### instance principal can mint a registry token (UP-6615). Repositories live in
### whichever compartment created them and the images to scan may span several, so
### a compartment-scoped grant would not reliably cover them — a tenancy admin must
### add it separately. The tenant module grants it via cs-registry-read
### (modules/_shared/iam/permissions.tf). Without it the scanner falls back to the
### static DOCKER_USER/DOCKER_PASSWORD credentials.

# CloudScanner secret access
resource "oci_identity_policy" "cs_dg_secret_access_policy" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = local.compartment_id
  name           = format("cs-secret-access-%s", local.resource_suffix_hyphen)
  description    = "Allow cloudscanner dynamic group to access secrets"
  statements     = module.iam.cloudscanner_secret_access_permissions
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
}

# CloudScanner functions permissions
resource "oci_identity_policy" "cs_dg_functions_policy" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = local.compartment_id
  name           = format("cs-functions-%s", local.resource_suffix_hyphen)
  description    = "Allow cloudscanner dynamic group to manage functions"
  statements     = module.iam.cloudscanner_functions_permissions
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
}

# CloudScanner object storage permissions
resource "oci_identity_policy" "cs_dg_object_storage_policy" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = local.compartment_id
  name           = format("cs-object-storage-%s", local.resource_suffix_hyphen)
  description    = "Allow cloudscanner dynamic group to access object storage"
  statements     = module.iam.cloudscanner_object_storage_permissions
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
}

# CloudScanner networking permissions for scaling
resource "oci_identity_policy" "cs_dg_networking_policy" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = local.compartment_id
  name           = format("cs-networking-%s", local.resource_suffix_hyphen)
  description    = "Allow cloudscanner dynamic group to manage networking for scaling"
  statements     = module.iam.cloudscanner_networking_permissions
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
}

# CloudScanner KMS permissions for encrypted volume restore
resource "oci_identity_policy" "cs_dg_kms_policy" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = local.compartment_id
  name           = format("cs-kms-%s", local.resource_suffix_hyphen)
  description    = "Allow cloudscanner dynamic group to delegate and use KMS keys in orchestrator compartment"
  statements     = module.iam.cloudscanner_compartment_kms_permissions
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
}

### Target Compartment Policies (created in each target compartment)

# Grant compute viewer policy to CloudScanner dynamic group on each target compartment
resource "oci_identity_policy" "upwind_cloudscanner_dg_compute_viewer_policy" {
  for_each = var.enable_cloudscanners ? toset(var.target_compartment_ids) : toset([])

  compartment_id = each.value
  name           = format("cs-compute-viewer-%s", local.resource_suffix_hyphen)
  description    = "Allow cloudscanner dynamic group to view compute resources"
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
  statements = [
    "Allow dynamic-group ${module.iam.cloudscanner_dg[0].name} to read instances in compartment id ${each.value}",
    "Allow dynamic-group ${module.iam.cloudscanner_dg[0].name} to read boot-volumes in compartment id ${each.value}",
    "Allow dynamic-group ${module.iam.cloudscanner_dg[0].name} to read block-volumes in compartment id ${each.value}"
  ]
}

# Grant snapshot (volume backup) management to CloudScanner dynamic group on each
# target compartment. Required for CreateVolumeBackup / CreateBootVolumeBackup.
#
# Without this, a compartment-scoped deployment can discover volumes (read-only
# viewer policy above) but every snapshot request is denied with
# NotAuthorizedOrNotFound, leaving scans stuck at SNAPSHOT_REQUESTED. The tenant
# module grants these tenancy-wide via cs-tenancy-snapshot-create (see
# modules/tenant/iam-roles-cloudscanner.tf); this is the compartment-scoped
# equivalent, applied to the compartment that holds the target volumes.
resource "oci_identity_policy" "upwind_cloudscanner_dg_snapshot_create_policy" {
  for_each = var.enable_cloudscanners ? toset(var.target_compartment_ids) : toset([])

  compartment_id = each.value
  name           = format("cs-snapshot-create-%s", local.resource_suffix_hyphen)
  description    = "Allow cloudscanner dynamic group to create volume snapshots (backups)"
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
  statements = [
    "Allow dynamic-group ${module.iam.cloudscanner_dg[0].name} to manage volume-family in compartment id ${each.value}",
    "Allow dynamic-group ${module.iam.cloudscanner_dg[0].name} to manage boot-volume-backups in compartment id ${each.value}"
  ]
}
