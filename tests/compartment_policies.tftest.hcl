# Guards the per-target-compartment policies: that their names are unique across
# the tenancy, and that the grants they carry stay at parity with tenant mode.
#
# OCI policy names must be unique across the whole tenancy, not just within the
# compartment holding the policy. Every policy created once per entry in
# target_compartment_ids therefore needs a discriminator, or the second
# compartment's policy collides with the first and the apply fails with a 409.
#
# A plan succeeds either way - the collision only surfaces when OCI is asked to
# create the second policy - so the broad "it plans" test in compartment.tftest.hcl
# cannot catch a regression here. These assertions can.
#
# This exercises modules/compartment directly rather than the root module,
# because the policy names are only exposed on the submodule's outputs.

mock_provider "oci" {
  mock_data "oci_identity_region_subscriptions" {
    defaults = {
      region_subscriptions = [
        {
          region_name    = "us-ashburn-1"
          is_home_region = true
          region_key     = "IAD"
          status         = "READY"
        },
      ]
    }
  }
}

variables {
  upwind_organization_id = "org_abcdef12345"
  upwind_client_id       = "testclientid"
  upwind_client_secret   = "test-client-secret"
  scanner_client_id      = "testscannerid"
  scanner_client_secret  = "test-scanner-secret"
  enable_cloudscanners   = true

  oci_tenancy_id                     = "ocid1.tenancy.oc1..aaaaaaaatesttenancy"
  upwind_orchestrator_compartment_id = "ocid1.compartment.oc1..aaaaaaaaorchestrator"

  target_compartment_ids = [
    "ocid1.compartment.oc1..aaaaaaaatargetone",
    "ocid1.compartment.oc1..aaaaaaaatargettwo",
    "ocid1.compartment.oc1..aaaaaaaatargetthree",
  ]
}

run "per_target_policy_names_are_unique" {
  command = plan

  module {
    source = "./modules/compartment"
  }

  assert {
    condition = length(distinct([
      for k, v in output.upwind_management_group_compartment_viewer_policies : v.name
    ])) == length(var.target_compartment_ids)
    error_message = "mgmt-compartment-viewer policy names repeat across target compartments; OCI requires policy names unique per tenancy."
  }

  assert {
    condition = length(distinct([
      for k, v in output.upwind_management_group_asset_viewer_policies : v.name
    ])) == length(var.target_compartment_ids)
    error_message = "mgmt-asset-viewer policy names repeat across target compartments; OCI requires policy names unique per tenancy."
  }

  assert {
    condition = length(distinct([
      for k, v in output.upwind_cloudscanner_dg_compute_viewer_policies : v.name
    ])) == length(var.target_compartment_ids)
    error_message = "cs-compute-viewer policy names repeat across target compartments; OCI requires policy names unique per tenancy."
  }

  assert {
    condition = length(distinct([
      for k, v in output.upwind_cloudscanner_dg_registry_read_policies : v.name
    ])) == length(var.target_compartment_ids)
    error_message = "cs-registry-read policy names repeat across target compartments; OCI requires policy names unique per tenancy."
  }

  assert {
    condition = length(distinct([
      for k, v in output.upwind_cloudscanner_dg_snapshot_create_policies : v.name
    ])) == length(var.target_compartment_ids)
    error_message = "cs-snapshot-create policy names repeat across target compartments; OCI requires policy names unique per tenancy."
  }

  assert {
    condition = length(distinct([
      for k, v in output.upwind_cloudscanner_dg_kms_policies : v.name
    ])) == length(var.target_compartment_ids)
    error_message = "cs-kms policy names repeat across target compartments; OCI requires policy names unique per tenancy."
  }

  # The discriminator must be derived from the compartment, not from anything
  # that changes between runs, or every plan would show a spurious replacement.
  assert {
    condition = alltrue([
      for k, v in output.upwind_cloudscanner_dg_kms_policies :
      endswith(v.name, substr(sha256(k), 0, 8))
    ])
    error_message = "cs-kms policy name does not end with the hash of its own target compartment OCID."
  }

  # OCI caps IAM policy names at 100 characters. The longest name here is
  # mgmt-compartment-viewer-<org><suffix>-<hash>; keep headroom visible so a
  # future prefix change does not silently overrun it.
  assert {
    condition = alltrue([
      for k, v in output.upwind_management_group_compartment_viewer_policies :
      length(v.name) <= 100
    ])
    error_message = "A policy name exceeds OCI's 100 character limit."
  }
}

# Guards grant parity between the two deployment modes.
#
# Tenant mode grants the CloudScanner dynamic group a set of permissions
# tenancy-wide (cloudscanner_tenancy_* in modules/_shared/iam/permissions.tf).
# Compartment mode has to grant the same set on each target compartment, or a
# scan that works for a tenancy-onboarded customer fails for a
# compartment-onboarded one - and fails partially, which is harder to diagnose
# than failing outright.
#
# A plan succeeds whether or not a grant is present, so only an assertion on the
# statements catches a dropped one.
#
# The one deliberate asymmetry is "use tag-namespaces", which tenant mode grants
# in tenancy. Tag namespaces live in the root compartment and cannot be granted
# from a compartment-scoped deployment at all, so it is excluded here and is
# documented as a manual step for a tenancy admin.
run "per_target_grants_match_tenant_mode" {
  command = plan

  module {
    source = "./modules/compartment"
  }

  assert {
    condition = alltrue([
      for compartment_id, policy in output.upwind_cloudscanner_dg_compute_viewer_policies :
      alltrue([
        for resource_type in [
          "instances",
          "instance-configurations",
          "instance-pools",
          "work-requests",
          "cluster-node-pools",
        ] :
        anytrue([
          for statement in policy.statements :
          strcontains(statement, "to read ${resource_type} in compartment id ${compartment_id}")
        ])
      ])
    ])
    error_message = "cs-compute-viewer is missing a read grant that tenant mode grants tenancy-wide. read work-requests in particular is required: volume backup creation is asynchronous and the work request is raised in the target compartment."
  }

  assert {
    condition = alltrue([
      for compartment_id, policy in output.upwind_cloudscanner_dg_snapshot_create_policies :
      anytrue([
        for statement in policy.statements :
        strcontains(statement, "to manage volume-family in compartment id ${compartment_id}")
      ])
    ])
    error_message = "cs-snapshot-create is missing manage volume-family; snapshot requests would be denied with NotAuthorizedOrNotFound."
  }

  assert {
    condition = alltrue([
      for compartment_id, policy in output.upwind_cloudscanner_dg_registry_read_policies :
      anytrue([
        for statement in policy.statements :
        strcontains(statement, "to read repos in compartment id ${compartment_id}")
      ])
    ])
    error_message = "cs-registry-read is missing read repos; the scanner cannot mint an OCIR token and falls back to static credentials."
  }

  # Both the dynamic group grants and the blockstorage service grant are needed:
  # the scanner authorises the backup, but Block Storage performs the decrypt.
  assert {
    condition = alltrue([
      for compartment_id, policy in output.upwind_cloudscanner_dg_kms_policies :
      alltrue([
        for required in [
          "to use key-delegate in compartment id",
          "to use keys in compartment id",
          "Allow service blockstorage to use keys in compartment id",
        ] :
        anytrue([
          for statement in policy.statements :
          strcontains(statement, "${required} ${compartment_id}")
        ])
      ])
    ])
    error_message = "cs-kms is missing a KMS grant on the target compartment; volumes encrypted with a customer-managed key would fail to snapshot while unencrypted ones succeed."
  }
}
