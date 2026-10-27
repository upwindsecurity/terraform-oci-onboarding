# "read all-resources" includes OBJECT_READ (object contents) and SECRET_BUNDLE_READ (secret values).
# Upwind's inventory only lists and describes resources, so every "read all-resources" grant must
# exclude those two permissions.

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

run "tenancy_read_grants_exclude_object_and_secret_contents" {
  assert {
    condition = length(concat(
      oci_identity_policy.federated_mgmt_group_tenancy_read_policy[0].statements,
      oci_identity_policy.federated_reader_group_tenancy_read_policy[0].statements,
    )) == 2
    error_message = "Expected one tenancy-wide read statement each for the management and reader groups."
  }

  assert {
    condition = alltrue([
      for statement in concat(
        oci_identity_policy.federated_mgmt_group_tenancy_read_policy[0].statements,
        oci_identity_policy.federated_reader_group_tenancy_read_policy[0].statements,
      ) : endswith(statement, "to read all-resources in tenancy where all {request.permission != 'OBJECT_READ', request.permission != 'SECRET_BUNDLE_READ'}")
    ])
    error_message = "Every \"read all-resources in tenancy\" grant must exclude OBJECT_READ and SECRET_BUNDLE_READ."
  }
}
