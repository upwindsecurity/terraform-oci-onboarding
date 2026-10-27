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

run "deployment_can_read_its_own_secret_bundles" {
  assert {
    condition = contains(
      output.federated_mgmt_group_secret_access_permissions,
      "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to read secret-bundles in compartment id ocid1.compartment.oc1..orchestrator",
    )
    error_message = "The management group must be able to read secret bundles in the orchestrator compartment, or the CloudScanner deployment cannot fetch its credentials."
  }

  assert {
    condition = alltrue([
      for statement in output.federated_mgmt_group_secret_access_permissions :
      !strcontains(statement, "in tenancy")
    ])
    error_message = "Secret access for the management group must stay scoped to the orchestrator compartment."
  }
}
