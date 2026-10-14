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

# Grant container registry read to the CloudScanner dynamic group on each target
# compartment. Required so the scanner's instance principal can mint an OCIR
# registry token and pull the images it scans (UP-6615).
#
# This covers repositories living in the compartments being onboarded, which is
# the common case. Repositories are compartment-scoped resources, so images held
# in a compartment that is NOT onboarded are not covered here - for those, a
# tenancy admin grants "read repos in tenancy", which the tenant module does via
# cs-registry-read (modules/tenant/iam-roles-cloudscanner.tf).
#
# Without a matching grant the token exchange is refused and the scanner falls
# back to the static DOCKER_USER/DOCKER_PASSWORD credentials.
resource "oci_identity_policy" "upwind_cloudscanner_dg_registry_read_policy" {
  for_each = var.enable_cloudscanners ? toset(var.target_compartment_ids) : toset([])

  compartment_id = each.value
  name           = format("cs-registry-read-%s-%s", local.resource_suffix_hyphen, local.target_compartment_discriminator[each.value])
  description    = "Allow cloudscanner dynamic group to read container registry repositories"
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
  statements = [
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to read repos in compartment id ${each.value}"
  ]
}

# Grant compute viewer policy to CloudScanner dynamic group on each target compartment.
# Volume reads come from "manage volume-family" in the snapshot policy below, which is
# created for the same compartments.
#
# This set mirrors the tenancy-wide cloudscanner_tenancy_compute_read_permissions_list
# in modules/_shared/iam/permissions.tf, which the tenant module grants via
# cs-tenancy-compute-read. Keep the two in step: a resource type readable in tenant
# mode but not here is a scan that silently works for one customer and not another.
#
# read work-requests in particular is not optional. Volume backup creation is
# asynchronous - CreateVolumeBackup returns a work request that the scanner polls to
# learn when the snapshot is usable - and the work request is created in the
# compartment the backup lands in, which is the target compartment, not the
# orchestrator.
resource "oci_identity_policy" "upwind_cloudscanner_dg_compute_viewer_policy" {
  for_each = var.enable_cloudscanners ? toset(var.target_compartment_ids) : toset([])

  compartment_id = each.value
  name           = format("cs-compute-viewer-%s-%s", local.resource_suffix_hyphen, local.target_compartment_discriminator[each.value])
  description    = "Allow cloudscanner dynamic group to view compute resources"
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
  statements = [
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to read instances in compartment id ${each.value}",
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to read instance-configurations in compartment id ${each.value}",
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to read instance-pools in compartment id ${each.value}",
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to read work-requests in compartment id ${each.value}",
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to read cluster-node-pools in compartment id ${each.value}"
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
  name           = format("cs-snapshot-create-%s-%s", local.resource_suffix_hyphen, local.target_compartment_discriminator[each.value])
  description    = "Allow cloudscanner dynamic group to create volume snapshots (backups)"
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
  statements = [
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to manage volume-family in compartment id ${each.value}"
  ]
}

# Grant KMS usage to the CloudScanner dynamic group on each target compartment.
#
# The cs-kms policy above covers the orchestrator compartment, which is where the
# scanner restores a snapshot into a working volume. That is only half the path.
# Snapshotting a volume that is encrypted with a customer-managed key also needs
# key access where the SOURCE key lives, and for a volume in a target compartment
# that key is in the customer's own vault, not the orchestrator's. Without this,
# unencrypted volumes scan fine and encrypted ones fail - a partial, confusing
# failure mode rather than an obvious one.
#
# The tenant module sidesteps the question by granting these tenancy-wide via
# cs-tenancy-kms (modules/tenant/iam-roles-cloudscanner.tf).
#
# Scope caveat: this covers keys held in the compartments being onboarded, which
# is the common arrangement. A tenancy that keeps its vaults in a separate
# security compartment that is NOT in target_compartment_ids still needs an
# equivalent grant added by hand on that compartment - see the compartment-mode
# prerequisites in the README.
#
# "Allow service blockstorage to use keys" is a service grant, not a dynamic-group
# grant: the Block Storage service itself performs the decrypt during the backup,
# so it needs its own permission on the key alongside the scanner's.
resource "oci_identity_policy" "upwind_cloudscanner_dg_kms_policy" {
  for_each = var.enable_cloudscanners ? toset(var.target_compartment_ids) : toset([])

  compartment_id = each.value
  name           = format("cs-kms-%s-%s", local.resource_suffix_hyphen, local.target_compartment_discriminator[each.value])
  description    = "Allow cloudscanner dynamic group to delegate and use KMS keys in target compartment"
  freeform_tags  = local.validated_tags
  defined_tags   = local.validated_defined_tags
  statements = [
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to use key-delegate in compartment id ${each.value}",
    "Allow dynamic-group ${module.iam.cloudscanner_dg.name} to use keys in compartment id ${each.value}",
    "Allow service blockstorage to use keys in compartment id ${each.value}"
  ]
}
