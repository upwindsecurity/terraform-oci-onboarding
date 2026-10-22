locals {
  compartment_id = var.upwind_orchestrator_compartment_id
  # Sanitize the org_id to be used in resource names
  # Dynamic group names can contain [a-zA-Z0-9_.-] and have a 100 character limit
  # We use hyphens as separators for consistency and readability
  org_id_sanitized = replace(lower(var.upwind_organization_id), "org_", "")

  # Truncate org_id to last 5 characters in lowercase to ensure it fits within resource name limits
  # Keep it reasonably short to leave room for other components
  org_id_truncated = substr(local.org_id_sanitized, length(local.org_id_sanitized) - 5, 5)

  # Create resource suffixes that include both org_id and user-provided suffix
  resource_suffix_hyphen = format("%s%s", local.org_id_truncated, var.resource_suffix == "" ? "" : "-${var.resource_suffix}")

  # Per-target-compartment name discriminator.
  #
  # OCI policy names must be unique across the whole TENANCY, not just within the
  # compartment that holds the policy. The policies below are created once per
  # entry in target_compartment_ids, so without a discriminator the second
  # compartment's policy collides with the first and the apply fails with a 409 -
  # compartment mode would only ever work with exactly one target compartment.
  #
  # (The ancestor this module was ported from, terraform-google-onboarding's
  # multiproject module, repeats one name across every target because a GCP
  # custom role ID only has to be unique within its project. That assumption does
  # not carry over to OCI.)
  #
  # A hash of the compartment OCID rather than a random_id: the name stays
  # derivable from the inputs alone, so it survives a state loss and never churns
  # on re-apply. 8 hex characters is ample - collisions would need two target
  # OCIDs sharing a 32-bit prefix - and keeps the longest resulting name
  # (mgmt-compartment-viewer-<suffix>-<hash>) at 49 characters against OCI's 100
  # character limit.
  target_compartment_discriminator = {
    for compartment_id in var.target_compartment_ids :
    compartment_id => substr(sha256(compartment_id), 0, 8)
  }

  # Merge default tags with user-provided tags
  # User tags override defaults if keys conflict
  merged_tags = merge(var.default_tags, var.tags)

  # Common validation for tags
  validated_tags = {
    for k, v in local.merged_tags : k => v
    if can(regex("^[a-zA-Z0-9_.-]{1,100}$", k)) && can(regex("^[a-zA-Z0-9_.-]{0,100}$", v))
  }

  # Defined tags validation (namespace-qualified, e.g., "mandatory_tags.Environment")
  # Keys must be in format "namespace.key" where both parts are 1-100 characters
  # Values must be 0-256 characters (OCI defined tag value limit)
  validated_defined_tags = {
    for k, v in var.defined_tags : k => v
    if can(regex("^[a-zA-Z0-9_.-]{1,100}\\.[a-zA-Z0-9_.-]{1,100}$", k)) && length(v) <= 256
  }
}
