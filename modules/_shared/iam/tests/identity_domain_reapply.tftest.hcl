# Every resource inside the identity domain (the OAuth app, its users, groups and token-exchange
# trust) is keyed on the domain's IDCS endpoint, and changing it replaces them. The endpoint used to
# come from a data source that reads the domain resource, so any in-place update to the domain
# deferred that read to apply, made the endpoint unknown, and replaced all of them. OCI's tag
# defaults add Oracle-Tags to the domain after create, so every re-apply rotated the OAuth client
# credentials and broke the Upwind connection. These tests pin the endpoint as known through an
# in-place domain update.

mock_provider "oci" {
  mock_resource "oci_identity_domain" {
    defaults = {
      id  = "ocid1.domain.oc1..upwindtest"
      url = "https://idcs-upwindtest.identity.oraclecloud.com:443"
    }
  }

  mock_data "oci_identity_domain" {
    defaults = {
      id  = "ocid1.domain.oc1..customer"
      url = "https://idcs-customer.identity.oraclecloud.com:443"
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
  vault_endpoint_wait                = "0s"
}

run "create_the_onboarding" {}

run "an_in_place_domain_update_keeps_the_domain_resources" {
  command = plan

  # Any in-place change to the domain, standing in for the Oracle-Tags OCI adds after create.
  variables {
    defined_tags = { "Upwind.Owner" = "security" }
  }

  assert {
    condition     = oci_identity_domains_app.upwind_identity_domain_oidc_client.idcs_endpoint == "https://idcs-upwindtest.identity.oraclecloud.com:443"
    error_message = "The OAuth app's endpoint must stay known when the domain is updated in place, or the app is replaced and its client credentials rotate."
  }

  assert {
    condition = alltrue([
      oci_identity_domains_user.upwind_management_user.idcs_endpoint == "https://idcs-upwindtest.identity.oraclecloud.com:443",
      oci_identity_domains_user.upwind_ro_user.idcs_endpoint == "https://idcs-upwindtest.identity.oraclecloud.com:443",
      oci_identity_domains_user.cloudscanner_user[0].idcs_endpoint == "https://idcs-upwindtest.identity.oraclecloud.com:443",
      oci_identity_domains_group.upwind_federated_mgmt_group.idcs_endpoint == "https://idcs-upwindtest.identity.oraclecloud.com:443",
      oci_identity_domains_group.upwind_federated_reader_group.idcs_endpoint == "https://idcs-upwindtest.identity.oraclecloud.com:443",
      oci_identity_domains_identity_propagation_trust.upwind_identity_domain_token_exchange_trust.idcs_endpoint == "https://idcs-upwindtest.identity.oraclecloud.com:443",
    ])
    error_message = "Every resource inside the domain must keep a known endpoint through an in-place domain update, or it is replaced."
  }
}

run "a_customer_supplied_domain_is_read_from_the_data_source" {
  command = plan

  variables {
    oci_domain_id        = "ocid1.domain.oc1..customer"
    identity_domain_name = "Default"
  }

  assert {
    condition     = length(oci_identity_domain.upwind_identity_domain) == 0
    error_message = "The module must not create a domain when oci_domain_id is supplied."
  }

  assert {
    condition     = oci_identity_domains_app.upwind_identity_domain_oidc_client.idcs_endpoint == "https://idcs-customer.identity.oraclecloud.com:443"
    error_message = "With a customer-supplied domain, the endpoint must come from that domain."
  }
}
