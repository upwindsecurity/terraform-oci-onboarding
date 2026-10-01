# The domain replication grant is "manage domains", which is only safe because of its conditions:
# target.domain.id limits it to the Upwind identity domain and request.permission limits it to
# replication. These tests pin the exact statements so a change that drops or loosens either
# condition fails CI, check the policy is attached where the domain lives (a policy only reaches
# resources in its own compartment and below), check no grant exists for a customer-supplied
# domain, and check the policy's precondition refuses a statement it cannot scope.

mock_provider "oci" {
  mock_data "oci_identity_domain" {
    defaults = {
      id           = "ocid1.domain.oc1..upwindtest"
      url          = "https://idcs-upwindtest.identity.oraclecloud.com:443"
      display_name = "upwind-identity-domain-test"
    }
  }
}

variables {
  upwind_client_id                   = "test-client-id"
  upwind_client_secret               = "test-client-secret"
  upwind_organization_id             = "org_test123"
  oci_tenancy_id                     = "ocid1.tenancy.oc1..testtenancy"
  upwind_orchestrator_compartment_id = "ocid1.compartment.oc1..orchestrator"
  resource_suffix                    = "test"
}

run "tenant_mode_grants_only_replication_of_the_upwind_domain" {
  variables {
    root_level_compartment_id = "ocid1.tenancy.oc1..testtenancy"
  }

  assert {
    condition     = length(oci_identity_policy.federated_mgmt_group_domain_replication_policy[0].statements) == 1
    error_message = "Tenant mode reads domains through \"read all-resources in tenancy\", so the policy should hold only the replication statement."
  }

  assert {
    condition = (
      oci_identity_policy.federated_mgmt_group_domain_replication_policy[0].statements[0] ==
      "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage domains in tenancy where all { target.domain.id = 'ocid1.domain.oc1..upwindtest', request.permission = 'DOMAIN_REPLICATE' }"
    )
    error_message = "The tenant-mode replication statement changed. It must stay limited to the Upwind domain and to DOMAIN_REPLICATE."
  }

  assert {
    condition     = oci_identity_policy.federated_mgmt_group_domain_replication_policy[0].compartment_id == oci_identity_domain.upwind_identity_domain[0].compartment_id
    error_message = "The replication policy must be attached to the compartment the Upwind identity domain is created in."
  }
}

run "compartment_mode_scopes_the_grant_to_the_domain_compartment" {
  variables {
    root_level_compartment_id = "ocid1.compartment.oc1..domaincompartment"
  }

  assert {
    condition = (
      oci_identity_policy.federated_mgmt_group_domain_replication_policy[0].statements ==
      tolist([
        "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to inspect domains in compartment id ocid1.compartment.oc1..domaincompartment",
        "Allow group id ${oci_identity_domains_group.upwind_federated_mgmt_group.ocid} to manage domains in compartment id ocid1.compartment.oc1..domaincompartment where all { target.domain.id = 'ocid1.domain.oc1..upwindtest', request.permission = 'DOMAIN_REPLICATE' }",
      ])
    )
    error_message = "The compartment-mode replication statements changed. The manage statement must stay limited to the Upwind domain and to DOMAIN_REPLICATE."
  }

  assert {
    condition = (
      oci_identity_domain.upwind_identity_domain[0].compartment_id == "ocid1.compartment.oc1..domaincompartment" &&
      oci_identity_policy.federated_mgmt_group_domain_replication_policy[0].compartment_id == "ocid1.compartment.oc1..domaincompartment"
    )
    error_message = "In compartment mode the domain and its replication policy must both live in root_level_compartment_id, or the policy does not reach the domain."
  }
}

run "no_grant_for_a_customer_supplied_domain" {
  variables {
    root_level_compartment_id = "ocid1.compartment.oc1..domaincompartment"
    oci_domain_id             = "ocid1.domain.oc1..customerdomain"
  }

  assert {
    condition     = length(oci_identity_policy.federated_mgmt_group_domain_replication_policy) == 0
    error_message = "A customer-supplied domain is the customer's to replicate, and may live outside root_level_compartment_id, so the module must not grant replication of it."
  }

  assert {
    condition     = length(oci_identity_domain.upwind_identity_domain) == 0
    error_message = "With oci_domain_id set the module must not create a domain."
  }
}

run "no_other_policy_grants_manage_domains" {
  variables {
    root_level_compartment_id = "ocid1.tenancy.oc1..testtenancy"
  }

  assert {
    condition = alltrue([
      for statement in concat(
        oci_identity_policy.federated_mgmt_group_tenancy_read_policy[0].statements,
        oci_identity_policy.federated_mgmt_group_tenancy_iam_policy[0].statements,
        oci_identity_policy.federated_mgmt_group_orchestrator_deploy_compute.statements,
        oci_identity_policy.federated_mgmt_group_orchestrator_deploy_functions.statements,
        oci_identity_policy.federated_mgmt_group_secret_access_policy.statements,
      ) : !can(regex("(?i)\\b(manage|use)\\s+domains\\b", statement))
    ])
    error_message = "Only the domain replication policy may grant use or manage on domains."
  }
}

run "refuses_a_grant_it_cannot_scope_to_a_domain" {
  variables {
    root_level_compartment_id = "ocid1.tenancy.oc1..testtenancy"
  }

  override_data {
    target = data.oci_identity_domain.upwind_identity_domain
    values = {
      id  = ""
      url = "https://idcs-upwindtest.identity.oraclecloud.com:443"
    }
  }

  command         = plan
  expect_failures = [oci_identity_policy.federated_mgmt_group_domain_replication_policy]
}
