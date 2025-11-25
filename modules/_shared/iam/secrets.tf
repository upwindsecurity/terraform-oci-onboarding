### Vault and Vault Key Resources

# Create the Vault for storing secrets
resource "oci_kms_vault" "upwind_vault" {
  compartment_id = local.compartment_id
  display_name   = format("upwind-vault-%s", local.resource_suffix_hyphen)
  # Required for software-only keys
  vault_type = "VIRTUAL_PRIVATE"
}

# Create the Vault Key for encryption
resource "oci_kms_key" "upwind_vault_key" {
  compartment_id      = local.compartment_id
  display_name        = format("upwind-vault-key-%s", local.resource_suffix_hyphen)
  management_endpoint = oci_kms_vault.upwind_vault.management_endpoint
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  # Required for software-only keys
  protection_mode = "SOFTWARE"
}

### Secrets used by Cloudscanners

resource "oci_vault_secret" "upwind_client_id" {
  compartment_id = local.compartment_id
  vault_id       = oci_kms_vault.upwind_vault.id
  key_id         = oci_kms_key.upwind_vault_key.id
  secret_name    = "upwind-client-id-${local.resource_suffix_hyphen}"
  secret_content {
    content      = base64encode(var.upwind_client_id)
    content_type = "BASE64"
  }
  description = "Upwind client ID for authentication"
}

resource "oci_vault_secret" "upwind_client_secret" {
  compartment_id = local.compartment_id
  vault_id       = oci_kms_vault.upwind_vault.id
  key_id         = oci_kms_key.upwind_vault_key.id
  secret_name    = "upwind-client-secret-${local.resource_suffix_hyphen}"
  secret_content {
    content      = base64encode(var.upwind_client_secret)
    content_type = "BASE64"
  }
  description = "Upwind client secret for authentication"
}

resource "oci_vault_secret" "scanner_client_id" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = local.compartment_id
  vault_id       = oci_kms_vault.upwind_vault.id
  key_id         = oci_kms_key.upwind_vault_key.id
  secret_name    = "upwind-scanner-client-id-${local.resource_suffix_hyphen}"
  secret_content {
    content      = base64encode(var.scanner_client_id)
    content_type = "BASE64"
  }
  description = "Upwind scanner client ID for authentication"
}

resource "oci_vault_secret" "scanner_client_secret" {
  count          = var.enable_cloudscanners ? 1 : 0
  compartment_id = local.compartment_id
  vault_id       = oci_kms_vault.upwind_vault.id
  key_id         = oci_kms_key.upwind_vault_key.id
  secret_name    = "upwind-scanner-client-secret-${local.resource_suffix_hyphen}"
  secret_content {
    content      = base64encode(var.scanner_client_secret)
    content_type = "BASE64"
  }
  description = "Upwind scanner client secret for authentication"
}

# Create an empty secret but apply the user-defined tags to the resource
resource "oci_vault_secret" "terraform_tags" {
  compartment_id = local.compartment_id
  vault_id       = oci_kms_vault.upwind_vault.id
  key_id         = oci_kms_key.upwind_vault_key.id
  secret_name    = "upwind-default-tags-${local.resource_suffix_hyphen}"
  secret_content {
    content      = base64encode("tags-stored-as-resource-metadata")
    content_type = "BASE64"
  }
  description = "Default tags stored as resource metadata"
}
