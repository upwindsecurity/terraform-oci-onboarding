# Upwind OCI Shared IAM Module

This module creates the shared IAM resources required for Upwind's cloud security platform integration with Oracle Cloud Infrastructure (OCI).

## Features

- **Dynamic Groups**: Creates dynamic groups for management and cloudscanner operations
- **Users**: Creates corresponding users for each dynamic group
- **Policies**: Implements fine-grained IAM policies for secure access control
- **Workload Identity Federation**: Supports AWS workload identity federation via OCI Identity Domain
- **Tag Management**: Applies consistent tagging across all resources (freeform_tags for standard resources, SCIM tags for Identity Domains resources)
- **Existing Domain Support**: Can use existing OCI Identity Domains or create new ones automatically

## Architecture

The module creates the following core components:

1. **Management Dynamic Group**: Handles deployment and orchestration operations
2. **CloudScanner Dynamic Group**: Performs security scanning across compartments (optional, if `enable_cloudscanners = true`)
3. **Identity Domain**: Enables workload identity federation with AWS (created automatically if `oci_domain_id` is not provided, or uses existing domain if `oci_domain_id` is provided)
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
  # oci_domain_id: if provided, uses existing domain; if not provided, creates new domain
  oci_domain_id = "ocid1.domain.oc1..xxxxx"  # Optional: use existing domain

  # Vault Configuration (optional)
  # If oci_vault_id is provided, secrets will be created in the existing vault
  # If oci_vault_key_id is not provided, a new key will be created in the existing vault
  oci_vault_id     = "ocid1.vault.oc1..xxxxx"  # Optional: use existing vault
  oci_vault_key_id = "ocid1.key.oc1..xxxxx"    # Optional: use existing key (or create new key in vault)

  # Optional Configuration
  enable_cloudscanners = true
  resource_suffix      = "prod"
  is_dev               = false

  # Tags (optional)
  # User-provided tags override default_tags if keys conflict
  tags = {
    environment = "production"
    team        = "security"
  }

  # Default tags (optional)
  # Applied to all resources, can be overridden by tags
  default_tags = {
    managed_by = "terraform"
    component  = "upwind"
  }
}
```

## Prerequisites

The deploying user must be an **Oracle Cloud Infrastructure (OCI) administrator** with the following requirements:

### Required IAM Permissions

The deploying user must be a member of a group (typically "Administrators") that has the following policy statement at the tenancy level:

```
Allow group Administrators to manage all-resources in tenancy
```

Alternatively, for more granular control, the following specific permissions are required:

```
Allow group Administrators to manage dynamic-groups in tenancy
Allow group Administrators to manage policies in tenancy
Allow group Administrators to manage users in tenancy
Allow group Administrators to manage groups in tenancy
Allow group Administrators to manage identity-providers in tenancy
Allow group Administrators to manage identity-domains in tenancy
Allow group Administrators to manage vaults in tenancy
Allow group Administrators to manage keys in tenancy
Allow group Administrators to manage secrets in tenancy
Allow group Administrators to manage compartments in tenancy
```

**Note**: Even if you are in the "Administrators" group, OCI requires explicit IAM policies to be created. Being an administrator does not automatically grant all permissions.

### Additional Requirements

- OCI Provider >= 7.0.0
- Terraform >= 1.0.0
- For workload identity federation: permissions to create identity domains (if `oci_domain_id` is not provided) or access to existing identity domain (if `oci_domain_id` is provided)
- For vault operations: permissions to create vaults and keys (if `oci_vault_id` is not provided) or access to existing vault (if `oci_vault_id` is provided)

## Resources Created

- Dynamic Groups (1-2): Management dynamic group (always), CloudScanner dynamic group (if `enable_cloudscanners = true`)
- Users (1-2): Management user (always), CloudScanner user (if `enable_cloudscanners = true`)
- IAM Policies (4): Orchestrator compartment policies for CloudScanner (3), Workload Identity Federation policy (1)
- Identity Domain (0-1): Created automatically if `oci_domain_id` is not provided, or uses existing domain if `oci_domain_id` is provided
- Workload Identity Federation Policy (1): AWS workload federation policy
- Vault (0-1): Created if `oci_vault_id` is not provided
- Vault Key (0-1): Created if `oci_vault_key_id` is not provided (or if using existing vault without key)
- Secrets (4): Upwind client ID/secret, scanner client ID/secret (if enabled)

## Vault Configuration

The module supports two modes for vault management:

1. **Create New Vault** (default): If `oci_vault_id` is not provided, the module will create a new VIRTUAL_PRIVATE vault and a new encryption key.

2. **Use Existing Vault**: If `oci_vault_id` is provided:
   - The module will use the existing vault via a data source
   - If `oci_vault_key_id` is also provided, it will use the existing key
   - If `oci_vault_key_id` is not provided, it will create a new key in the existing vault

All secrets (client IDs and client secrets) are stored in the vault using the specified encryption key.

## Tagging

The module supports comprehensive tagging across all resources:

- **Default Tags**: Applied to all resources by default (includes `managed_by=terraform` and `component=upwind`)
- **User Tags**: Can override or extend default tags via the `tags` variable
- **Tag Validation**: Tags are validated to ensure they meet OCI requirements (key: 1-100 alphanumeric characters, value: 0-100 alphanumeric characters)
- **Resource Coverage**: Tags are applied to:
  - KMS Vaults and Keys
  - Vault Secrets
  - Identity Users and Dynamic Groups
  - IAM Policies
  - Identity Domains (using freeform_tags)
  - Identity Domains resources (Apps, Users, Groups, Trusts) using SCIM-based tags with OCITags extension

When using an existing identity domain (`oci_domain_id` provided), tags are still applied to all resources created within that domain.

## Security Considerations

- Dynamic groups use least-privilege access principles
- Policies are scoped to specific compartments
- Workload identity federation provides secure external authentication via OIDC
- Resource naming includes organization ID for multi-tenant support
- Identity domain supports secure federation with external identity providers (e.g., AWS IAM)
- All secrets are encrypted using OCI Vault with AES-256 encryption
- Secrets are stored securely and never exposed in Terraform state or outputs
- Comprehensive tagging support for resource management and cost tracking
- Automatic domain detection: uses existing domain if `oci_domain_id` is provided, creates new one otherwise
