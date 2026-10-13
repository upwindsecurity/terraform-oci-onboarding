# Tenant-mode regression tests.
#
# Tenant mode is the released path, so it is the one with most to lose from a
# change made for compartment mode. The root module declares a single set of
# variables for both, so a validation rule or default altered for one mode
# reaches the other.
#
# Runs offline against a mocked OCI provider; see tests/compartment.tftest.hcl
# for why these exist at all.

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
        {
          region_name    = "us-phoenix-1"
          is_home_region = false
          region_key     = "PHX"
          status         = "READY"
        },
      ]
    }
  }
}

variables {
  deployment_mode        = "tenant"
  upwind_organization_id = "org_abcdef12345"
  upwind_client_id       = "testclientid"
  upwind_client_secret   = "test-client-secret"

  oci_tenancy_id                  = "ocid1.tenancy.oc1..aaaaaaaatesttenancy"
  upwind_orchestrator_compartment = "ocid1.compartment.oc1..aaaaaaaaorchestrator"
}

run "tenant_mode_plans_with_cloudscanners" {
  command = plan

  variables {
    enable_cloudscanners  = true
    scanner_client_id     = "testscannerid"
    scanner_client_secret = "test-scanner-secret"
  }

  assert {
    condition     = output.deployment_mode == "tenant"
    error_message = "Expected the tenant module to be the active deployment mode."
  }

  # Compartment-mode outputs must stay null in tenant mode rather than erroring:
  # the root module reaches into module.compartment[0] for them, which is empty
  # when tenant mode is selected.
  assert {
    condition     = output.target_compartment_ids == null
    error_message = "Expected target_compartment_ids to be null in tenant mode."
  }
}

run "tenant_mode_plans_without_cloudscanners" {
  command = plan

  variables {
    enable_cloudscanners = false
  }

  assert {
    condition     = output.deployment_mode == "tenant"
    error_message = "Expected the tenant module to be the active deployment mode."
  }
}

# The licence type is declared on the root module and on both submodules. They
# drifted apart once already - the compartment module required an uppercase set
# that the shared IAM module rejected, so no value satisfied a compartment
# deployment and the mode could never be applied. This pins the default to a
# value every layer accepts.
run "default_licence_type_is_accepted_by_every_layer" {
  command = plan

  assert {
    condition     = var.identity_domain_license_type == "free"
    error_message = "The default identity_domain_license_type changed; confirm the root module and BOTH submodules still accept it before updating this test."
  }
}
