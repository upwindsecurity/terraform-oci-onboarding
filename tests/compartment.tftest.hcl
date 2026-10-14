# Compartment-mode regression tests.
#
# These run entirely offline against a mocked OCI provider - no tenancy, no
# credentials - so they are safe to run on every pull request.
#
# They exist because `terraform validate`, which is all CI ran for a long time,
# does not evaluate variable validation rules or resource expressions against
# real values. Compartment mode was consequently merged in a state where it
# could not complete a plan at all, and that went unnoticed through several
# pull requests. A plan is the cheapest thing that would have caught it.

mock_provider "oci" {
  # The module lists the tenancy's subscribed regions to decide where to
  # replicate the identity domain. A mocked data source returns null for a
  # nested list unless it is given a value, and the module iterates it.
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
  deployment_mode        = "compartment"
  upwind_organization_id = "org_abcdef12345"
  upwind_client_id       = "testclientid"
  upwind_client_secret   = "test-client-secret"

  oci_tenancy_id                     = "ocid1.tenancy.oc1..aaaaaaaatesttenancy"
  upwind_orchestrator_compartment_id = "ocid1.compartment.oc1..aaaaaaaaorchestrator"

  target_compartment_ids = [
    "ocid1.compartment.oc1..aaaaaaaatargetone",
    "ocid1.compartment.oc1..aaaaaaaatargettwo",
    "ocid1.compartment.oc1..aaaaaaaatargetthree",
  ]
}

# Compartment mode must reach a complete plan with CloudScanners enabled.
#
# This is the broad regression guard. It fails on any expression error, any
# variable validation conflict between the root module and a submodule, and any
# unresolvable reference - the three classes of defect that made compartment
# mode undeployable. The assertions below are secondary to the plan simply
# succeeding.
run "compartment_mode_plans_with_cloudscanners" {
  command = plan

  variables {
    enable_cloudscanners  = true
    scanner_client_id     = "testscannerid"
    scanner_client_secret = "test-scanner-secret"
  }

  assert {
    condition     = output.deployment_mode == "compartment"
    error_message = "Expected the compartment module to be the active deployment mode."
  }

  assert {
    condition     = length(output.target_compartment_ids) == 3
    error_message = "Expected all three target compartments to be carried through to the compartment module."
  }
}

# Compartment mode must also plan with CloudScanners disabled, which takes a
# different path through every `count = var.enable_cloudscanners ? 1 : 0` and
# every `for_each = var.enable_cloudscanners ? toset(...) : toset([])`.
run "compartment_mode_plans_without_cloudscanners" {
  command = plan

  variables {
    enable_cloudscanners = false
  }

  assert {
    condition     = output.deployment_mode == "compartment"
    error_message = "Expected the compartment module to be the active deployment mode."
  }
}
