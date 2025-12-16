locals {
  upwind_aws_account = var.is_dev ? "437279811180" : "627244208106"
  timestamp          = formatdate("YYYYMMDD-hhmm", timestamp())

  # Determine the identity domain name prefix for policy statements
  # If creating a domain, use its display_name; otherwise use the provided name
  identity_domain_name_prefix = var.create_identity_domain ? (
    try(oci_identity_domain.upwind_identity_domain[0].display_name, "") != "" ?
    "'${oci_identity_domain.upwind_identity_domain[0].display_name}'/" :
    ""
    ) : (
    var.identity_domain_name != "" ? "'${var.identity_domain_name}'/" : ""
  )
}



### Workload Identity Federation for AWS to OCI Authentication
### See: https://docs.oracle.com/en-us/iaas/Content/Identity/domains/overview.htm

data "oci_identity_domain" "upwind_identity_domain" {
  domain_id = var.create_identity_domain ? try(oci_identity_domain.upwind_identity_domain[0].id, var.identity_domain_id) : var.identity_domain_id
}

# Create Identity Domain for workload identity federation
# NOTE: OCI Identity Domains cannot be deleted once in CREATED status.
resource "oci_identity_domain" "upwind_identity_domain" {
  count          = var.create_identity_domain ? 1 : 0
  compartment_id = var.root_level_compartment_id
  display_name   = var.identity_domain_display_name != "" ? var.identity_domain_display_name : format("upwind-identity-domain-%s", local.resource_suffix_hyphen)
  description    = var.identity_domain_description
  license_type   = var.identity_domain_license_type
  home_region    = var.oci_region

  lifecycle {
    precondition {
      condition     = var.identity_domain_display_name != "" || local.resource_suffix_hyphen != ""
      error_message = "Either identity_domain_display_name must be provided or resource_suffix must be set when creating an identity domain."
    }
    # Ignore changes to description as it's not critical and may be updated externally
    ignore_changes = [description]
  }
}

resource "oci_identity_domains_app" "upwind_identity_domain_oidc_client" {
  idcs_endpoint = data.oci_identity_domain.upwind_identity_domain.url
  display_name  = "upwind-identity-domain-oidc-client-${local.resource_suffix_hyphen}"
  active        = true
  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:App",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
  ]
  is_oauth_client = true
  client_type     = "confidential"
  allowed_grants  = ["client_credentials"]
  based_on_template {
    value = "CustomWebAppTemplateId"
  }

  depends_on = [oci_identity_domain.upwind_identity_domain]
}

# Create Identity Domain user for management operations
# This user corresponds to the OCI IAM user and is used for token exchange
resource "oci_identity_domains_user" "upwind_management_user" {
  idcs_endpoint = data.oci_identity_domain.upwind_identity_domain.url
  user_name     = oci_identity_user.upwind_management_user.email
  description   = "deployment"

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }

  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:userState:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:capabilities:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User",
  ]

  depends_on = [
    oci_identity_user.upwind_management_user,
    oci_identity_domain.upwind_identity_domain
  ]
}

resource "oci_identity_domains_user" "upwind_ro_user" {
  idcs_endpoint = data.oci_identity_domain.upwind_identity_domain.url
  user_name     = oci_identity_user.upwind_ro_user.email
  description   = "reader"

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }

  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:userState:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:capabilities:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User",
  ]

  depends_on = [
    oci_identity_user.upwind_ro_user,
    oci_identity_domain.upwind_identity_domain
  ]
}

resource "oci_identity_domains_user" "cloudscanner_user" {
  count         = var.enable_cloudscanners ? 1 : 0
  idcs_endpoint = data.oci_identity_domain.upwind_identity_domain.url
  user_name     = oci_identity_user.cloudscanner_user[0].email
  description   = "cloudscanner"

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }

  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:userState:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:capabilities:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User",
  ]

  depends_on = [
    oci_identity_user.cloudscanner_user,
    oci_identity_domain.upwind_identity_domain
  ]
}

resource "oci_identity_domains_identity_propagation_trust" "upwind_identity_domain_token_exchange_trust" {
  idcs_endpoint       = data.oci_identity_domain.upwind_identity_domain.url
  issuer              = var.is_dev ? "upwind.dev" : "upwind.io"
  name                = "upwind-identity-domain-token-exchange-trust-${local.resource_suffix_hyphen}"
  schemas             = ["urn:ietf:params:scim:schemas:oracle:idcs:IdentityPropagationTrust"]
  type                = "JWT"
  active              = true
  allow_impersonation = true
  oauth_clients       = [oci_identity_domains_app.upwind_identity_domain_oidc_client.name]
  public_key_endpoint = var.is_dev ? "https://get.upwind.dev/auth/oracle/jwks.json" : "https://get.upwind.io/auth/oracle/jwks.json"
  subject_type        = "User"
  description         = "Created by Terraform"

  dynamic "impersonation_service_users" {
    for_each = {
      for u in [
        oci_identity_domains_user.upwind_management_user,
        oci_identity_domains_user.upwind_ro_user,
        var.enable_cloudscanners ? oci_identity_domains_user.cloudscanner_user[0] : null
      ] :
      u.user_name => u
    }
    content {
      rule  = "role eq ${impersonation_service_users.value.description}"
      value = impersonation_service_users.value.id
    }
  }

  depends_on = [
    oci_identity_user.upwind_management_user,
    oci_identity_user.upwind_ro_user,
    oci_identity_domains_user.upwind_management_user,
    oci_identity_domains_user.upwind_ro_user,
    oci_identity_domains_app.upwind_identity_domain_oidc_client
  ]
}


output "trust_id" {
  value = oci_identity_domains_identity_propagation_trust.upwind_identity_domain_token_exchange_trust.id
}

