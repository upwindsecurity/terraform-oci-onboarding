# Any "manage policies" grant lets its holder write a policy giving itself more access, and
# Terraform creates every policy, dynamic group and user Upwind needs at apply time. No Upwind
# identity may be granted IAM write in the tenancy.

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

run "no_upwind_identity_gets_iam_write" {
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
        output.federated_mgmt_group_tenancy_read_permissions,
        output.federated_mgmt_group_secret_access_permissions,
        oci_identity_policy.federated_reader_group_tenancy_read_policy[0].statements,
      ) : !can(regex("(?i)\\b(manage|use)\\s+(policies|dynamic-groups|users|groups)\\b", statement))
    ])
    error_message = "No Upwind identity may be granted manage or use on policies, dynamic groups, users or groups."
  }

  assert {
    condition     = length(output.federated_mgmt_group_tenancy_iam_permissions) == 0
    error_message = "The deprecated federated_mgmt_group_tenancy_iam_permissions output must stay empty."
  }
}
