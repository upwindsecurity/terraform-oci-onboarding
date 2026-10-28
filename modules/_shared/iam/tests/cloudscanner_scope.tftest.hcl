mock_provider "oci" {
  mock_data "oci_identity_domain" {
    defaults = {
      id  = "ocid1.domain.oc1..upwindtest"
      url = "https://idcs-upwindtest.identity.oraclecloud.com:443"
    }
  }
}

variables {
  upwind_client_id                   = "test-client-id"
  upwind_client_secret               = "test-client-secret"
  scanner_client_id                  = "test-scanner-id"
  scanner_client_secret              = "test-scanner-secret"
  upwind_organization_id             = "org_test123"
  oci_tenancy_id                     = "ocid1.tenancy.oc1..testtenancy"
  upwind_orchestrator_compartment_id = "ocid1.compartment.oc1..orchestrator"
  root_level_compartment_id          = "ocid1.tenancy.oc1..testtenancy"
  resource_suffix                    = "test"
  enable_cloudscanners               = true
  vault_endpoint_wait                = "0s"
}

run "dynamic_group_matches_only_the_orchestrator_compartment" {
  command = plan

  assert {
    condition     = oci_identity_dynamic_group.cloudscanner_dg[0].matching_rule == "ALL {instance.compartment.id = 'ocid1.compartment.oc1..orchestrator'}"
    error_message = "The CloudScanner dynamic group must match only instances in the orchestrator compartment, not every instance in the tenancy."
  }
}

run "deploy_policies_exist_when_cloudscanner_is_enabled" {
  command = plan

  assert {
    condition     = length(oci_identity_policy.federated_mgmt_group_orchestrator_deploy_compute) == 1
    error_message = "The management group needs its orchestrator compute deploy policy to run CloudScanner."
  }

  assert {
    condition     = length(oci_identity_policy.federated_mgmt_group_orchestrator_deploy_functions) == 1
    error_message = "The management group needs its orchestrator functions deploy policy to run CloudScanner."
  }
}

run "no_scanner_or_deploy_grants_when_cloudscanner_is_disabled" {
  command = plan

  variables {
    enable_cloudscanners = false
  }

  assert {
    condition     = length(oci_identity_dynamic_group.cloudscanner_dg) == 0
    error_message = "The CloudScanner dynamic group must not exist when CloudScanner is disabled."
  }

  assert {
    condition     = length(oci_identity_policy.federated_mgmt_group_orchestrator_deploy_compute) == 0
    error_message = "The management group must not get orchestrator compute deploy rights when CloudScanner is disabled."
  }

  assert {
    condition     = length(oci_identity_policy.federated_mgmt_group_orchestrator_deploy_functions) == 0
    error_message = "The management group must not get orchestrator functions deploy rights when CloudScanner is disabled."
  }
}

run "scanner_volume_grant_is_limited_to_scanning" {
  command = plan

  assert {
    condition = alltrue([
      for s in output.cloudscanner_tenancy_snapshot_create_permissions :
      strcontains(s, " where ")
      && !strcontains(s, "= 'VOLUME_DELETE'") && !strcontains(s, "= 'VOLUME_CREATE'") && !strcontains(s, "= 'VOLUME_UPDATE'")
      if strcontains(s, "volume-family")
    ])
    error_message = "Outside the orchestrator the scanner may only read volumes and create and delete backups."
  }

  assert {
    condition = alltrue([
      for s in output.cloudscanner_tenancy_snapshot_create_permissions :
      strcontains(s, "request.operation = 'CreateVolumeBackup'") || strcontains(s, "request.operation = 'CreateBootVolumeBackup'")
      if strcontains(s, "'VOLUME_WRITE'")
    ])
    error_message = "VOLUME_WRITE must be limited to the backup operations, or the scanner can attach customer volumes."
  }

  assert {
    condition     = length([for s in output.cloudscanner_tenancy_snapshot_create_permissions : s if strcontains(s, "volume-family")]) == 3
    error_message = "Expected the scan permissions statement plus one VOLUME_WRITE statement per backup operation."
  }
}

run "object_storage_grant_needs_dspm" {
  command = plan

  assert {
    condition     = length(output.cloudscanner_object_storage_permissions) == 0
    error_message = "The scanner must not get object storage access unless DSPM scanning is enabled."
  }
}

run "object_storage_grant_with_dspm" {
  command = plan

  variables {
    enable_dspm_scanning = true
  }

  assert {
    condition     = length(output.cloudscanner_object_storage_permissions) == 2
    error_message = "DSPM scanning keeps the scanner's object storage grant."
  }
}
