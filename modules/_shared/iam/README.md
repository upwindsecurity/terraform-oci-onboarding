# Upwind OCI Shared IAM Module

This module creates the shared IAM resources required for Upwind's cloud security platform integration with Oracle Cloud Infrastructure (OCI).

## Features

- **Dynamic Groups**: Creates dynamic groups for management and cloudscanner operations
- **Users**: Creates corresponding users for each dynamic group
- **Policies**: Implements fine-grained IAM policies for secure access control
- **Workload Identity Federation**: Supports AWS workload identity federation via OCI Identity Domain
- **Tag Management**: Applies consistent tagging across all resources

## Architecture

The module creates the following core components:

1. **Management Dynamic Group**: Handles deployment and orchestration operations
2. **CloudScanner Dynamic Group**: Performs security scanning across compartments (optional, if `enable_cloudscanners = true`)
3. **Identity Domain**: Enables workload identity federation with AWS (optional, if `create_identity_domain = true`)
4. **Orchestrator Compartment Policies**: Grants CloudScanner permissions for volume and snapshot management
5. **Workload Identity Federation Policy**: Allows AWS workloads to authenticate to OCI via OIDC

## Usage

```hcl
module "upwind_shared_iam" {
  source = "./modules/_shared/iam"

  # OCI Configuration
  oci_region                         = "us-ashburn-1"
  oci_tenancy_id                     = "ocid1.tenancy.oc1..xxxxx"
  upwind_orchestrator_compartment_id = "ocid1.compartment.oc1..xxxxx"

  # Upwind Configuration
  upwind_organization_id = "org_12345"
  upwind_client_id       = "your-client-id"
  upwind_client_secret   = "your-client-secret"

  # Workload Identity Federation Configuration
  root_level_compartment_id = "ocid1.tenancy.oc1..xxxxx"  # or compartment OCID
  create_identity_domain    = true

  # Vault Configuration (optional)
  # If oci_vault_id is provided, secrets will be created in the existing vault
  # If oci_vault_key_id is not provided, a new key will be created in the existing vault
  oci_vault_id     = "ocid1.vault.oc1..xxxxx"  # Optional: use existing vault
  oci_vault_key_id = "ocid1.key.oc1..xxxxx"    # Optional: use existing key (or create new key in vault)

  # Optional Configuration
  enable_cloudscanners = true
  resource_suffix      = "prod"
  is_dev               = false

  # Tags
  tags = {
    environment = "production"
    team        = "security"
  }
}
```

## Requirements

- OCI Provider >= 7.0.0
- Terraform >= 1.0.0
- Appropriate IAM permissions to create dynamic groups, users, and policies
- For workload identity federation: permissions to create identity domains (if `create_identity_domain = true`) or access to existing identity domain
- For vault operations: permissions to create vaults and keys (if `oci_vault_id` is not provided) or access to existing vault (if `oci_vault_id` is provided)

## Resources Created

- Dynamic Groups (1-2): Management dynamic group (always), CloudScanner dynamic group (if `enable_cloudscanners = true`)
- Users (1-2): Management user (always), CloudScanner user (if `enable_cloudscanners = true`)
- IAM Policies (4): Orchestrator compartment policies for CloudScanner (3), Workload Identity Federation policy (1)
- Identity Domain (0-1): Created if `create_identity_domain = true`
- Workload Identity Federation Policy (1): AWS workload federation policy
- Vault (0-1): Created if `oci_vault_id` is not provided
- Vault Key (0-1): Created if `oci_vault_key_id` is not provided (or if using existing vault without key)
- Secrets (4-5): Upwind client ID/secret, scanner client ID/secret (if enabled), and terraform tags secret

## Vault Configuration

The module supports two modes for vault management:

1. **Create New Vault** (default): If `oci_vault_id` is not provided, the module will create a new VIRTUAL_PRIVATE vault and a new encryption key.

2. **Use Existing Vault**: If `oci_vault_id` is provided:
   - The module will use the existing vault via a data source
   - If `oci_vault_key_id` is also provided, it will use the existing key
   - If `oci_vault_key_id` is not provided, it will create a new key in the existing vault

All secrets (client IDs, client secrets, and tags) are stored in the vault using the specified encryption key.

## Security Considerations

- Dynamic groups use least-privilege access principles
- Policies are scoped to specific compartments
- Workload identity federation provides secure external authentication via OIDC
- Resource naming includes organization ID for multi-tenant support
- Identity domain supports secure federation with external identity providers (e.g., AWS IAM)
- All secrets are encrypted using OCI Vault with AES-256 encryption
- Secrets are stored securely and never exposed in Terraform state or outputs
