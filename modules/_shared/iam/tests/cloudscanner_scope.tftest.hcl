# The CloudScanner dynamic group holds tenancy-wide snapshot and key permissions, so its matching
# rule decides which instances get them. It used to match every instance in the tenancy; it must
# match only the orchestrator compartment, where Upwind runs its scanner instances.

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
}

run "dynamic_group_matches_only_the_orchestrator_compartment" {
  command = plan

  assert {
    condition     = oci_identity_dynamic_group.cloudscanner_dg[0].matching_rule == "ALL {instance.compartment.id = 'ocid1.compartment.oc1..orchestrator'}"
    error_message = "The CloudScanner dynamic group must match only instances in the orchestrator compartment, not every instance in the tenancy."
  }
}
