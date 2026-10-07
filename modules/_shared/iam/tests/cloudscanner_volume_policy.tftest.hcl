# OCI accepts a policy statement naming a resource type that doesn't exist, and it then grants
# nothing. "block-volumes" and "boot-volumes" are not resource types (volumes, boot volumes included,
# are "volumes"), so statements using them silently left compartment-mode CloudScanner unable to
# restore, attach or delete its scan volumes. These tests pin the orchestrator compartment grants
# and reject those resource types anywhere the module grants permissions.

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
  root_level_compartment_id          = "ocid1.compartment.oc1..orchestrator"
  resource_suffix                    = "test"
  enable_cloudscanners               = true
}

run "orchestrator_compartment_grants_the_scan_volume_lifecycle" {
  assert {
    condition = (
      oci_identity_policy.cs_dg_orchestrator_volume_policy[0].statements ==
      tolist([
        "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage volumes in compartment id ocid1.compartment.oc1..orchestrator",
        "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage volume-attachments in compartment id ocid1.compartment.oc1..orchestrator",
        "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage instances in compartment id ocid1.compartment.oc1..orchestrator",
        "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage instance-pools in compartment id ocid1.compartment.oc1..orchestrator",
        "Allow dynamic-group ${oci_identity_dynamic_group.cloudscanner_dg[0].name} to manage instance-configurations in compartment id ocid1.compartment.oc1..orchestrator",
      ])
    )
    error_message = "The scanner restores, attaches and deletes its volumes in the orchestrator compartment, so it needs manage volumes and manage volume-attachments there."
  }

  assert {
    condition     = oci_identity_policy.cs_dg_orchestrator_volume_policy[0].compartment_id == "ocid1.compartment.oc1..orchestrator"
    error_message = "The orchestrator volume policy must be attached to the orchestrator compartment."
  }
}

run "no_statement_names_a_resource_type_oci_does_not_have" {
  assert {
    condition = alltrue([
      for statement in concat(
        output.cloudscanner_tenancy_compute_read_permissions,
        output.cloudscanner_tenancy_registry_read_permissions,
        output.cloudscanner_tenancy_snapshot_create_permissions,
        output.cloudscanner_tenancy_kms_permissions,
        output.cloudscanner_compartment_kms_permissions,
        output.cloudscanner_orchestrator_volume_permissions,
        output.cloudscanner_secret_access_permissions,
        output.cloudscanner_functions_permissions,
        output.cloudscanner_object_storage_permissions,
        output.cloudscanner_networking_permissions,
        output.federated_mgmt_group_orchestrator_deploy_compute_permissions,
        output.federated_mgmt_group_orchestrator_deploy_network_permissions,
        output.federated_mgmt_group_orchestrator_deploy_functions_permissions,
        output.federated_mgmt_group_secret_access_permissions,
      ) : !can(regex("(?i)\\b(block|boot)-volumes\\b", statement))
    ])
    error_message = "\"block-volumes\" and \"boot-volumes\" are not OCI resource types, so a statement using them grants nothing. Use \"volumes\" (or \"volume-family\")."
  }
}
