# Upwind OCI Compartment Module

This module deploys Upwind's cloud security platform at the compartment level in Oracle Cloud Infrastructure (OCI), providing security scanning and monitoring for specific compartments within a tenancy. This module is designed for deployments where only compartment-level permissions are available.

## Features

- **Multi-Compartment Access**: Grants Upwind access to multiple target compartments
- **Compartment-Scoped Policies**: Creates policies directly in each target compartment
- **CloudScanner Integration**: Optional CloudScanner deployment for comprehensive security scanning
- **DSPM Scanning**: Optional Data Security Posture Management scanning
- **Workload Identity Federation**: Secure authentication with external identity providers
- **Fine-Grained Permissions**: Least-privilege access with compartment-scoped policies
- **Multi-Tenant Support**: Support for multiple Upwind organizations

## Architecture

The module creates the following components:

1. **Shared IAM Module**: Establishes core identity and access management
2. **Compartment Policies**: Creates policies directly in each target compartment
3. **CloudScanner Policies**: Optional policies for security scanning operations
4. **Asset Discovery**: Enables discovery of resources across compartments

## Usage

```hcl
module "upwind_compartment" {
  source = "./modules/compartment"

  # OCI Configuration
  oci_region                         = "us-ashburn-1"
  oci_tenancy_id                     = "ocid1.tenancy.oc1..xxxxx"
  upwind_orchestrator_compartment_id = "ocid1.compartment.oc1..xxxxx"

  # Target Compartments
  target_compartment_ids = [
    "ocid1.compartment.oc1..compartment1",
    "ocid1.compartment.oc1..compartment2",
    "ocid1.compartment.oc1..compartment3"
  ]

  # Upwind Configuration
  upwind_organization_id = "org_12345"
  upwind_client_id       = "your-client-id"
  upwind_client_secret   = "your-client-secret"

  # Workload Identity Federation (optional - has defaults)
  # root_level_compartment_id defaults to orchestrator compartment_id
  # oci_domain_id: if provided, uses existing domain; if not provided, creates new domain
  oci_domain_id = "ocid1.domain.oc1..xxxxx"  # Optional: use existing domain

  # Vault Configuration (optional)
  # If oci_vault_id is provided, secrets will be created in the existing vault
  # If oci_vault_key_id is not provided, a new key will be created in the existing vault
  oci_vault_id     = "ocid1.vault.oc1..xxxxx"  # Optional: use existing vault
  oci_vault_key_id = "ocid1.key.oc1..xxxxx"    # Optional: use existing key (or create new key in vault)
  vault_endpoint_wait = "6m"                  # Optional: wait after a new vault is ACTIVE before creating its key (default 6m)
                                              # Existing deployments: set "0s" on the first apply after upgrading to skip the one-time wait

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

**Note**: Even if you are in the "Administrators" group, OCI requires explicit IAM policies to be created. Being an administrator does not automatically grant all permissions. While this module operates at the compartment level, it still requires tenancy-level permissions to create IAM resources (users, dynamic groups, identity domains, etc.).

### Additional Requirements

- OCI Provider >= 5.0.0
- Terraform >= 1.0.0
- Target compartments must exist
- For vault operations: permissions to create vaults and keys (if `oci_vault_id` is not provided) or access to existing vault (if `oci_vault_id` is provided)
- For workload identity federation: permissions to create identity domains (if `oci_domain_id` is not provided) or access to existing identity domain (if `oci_domain_id` is provided)

## Resources Created

- IAM Policies (3+ per target compartment)
- Policy Attachments (3+ per target compartment)
- CloudScanner Policies (3+ per target compartment, if enabled)
- Shared IAM Module Resources (including vault, keys, and secrets)

## Security Model

- **Compartment Isolation**: Policies are created directly in target compartments
- **Least Privilege**: Minimal required permissions for each operation
- **Conditional Access**: Policy conditions exclude object contents and secret values, and limit CloudScanner volume access to scanning
- **Audit Trail**: All operations are logged and auditable
- **Encryption**: All secrets are encrypted using OCI Vault

## CloudScanner Features

When `enable_cloudscanners = true`, the CloudScanner dynamic group (scanner instances in the orchestrator compartment)
can:

- Read instances, node pools and container images in the target compartments
- Read volumes and create and delete volume backups in the target compartments, with no other volume access
- Restore, attach and delete scan volumes in the orchestrator compartment

## Audit Logs

When `enable_cloudlogs = true`, the module provides:

- **Audit Logs User and Group**: Read access to the audit-logs bucket and stream created by `terraform-oci-cloudlogs`

## DSPM Scanning

DSPM scanning is not yet supported on OCI. `enable_dspm_scanning = true` only grants CloudScanner read access to
buckets and objects in the orchestrator compartment.

## Differences from Tenant Module

The compartment module differs from the tenant module in that:

- **Compartment-Level Scope**: Policies are created at the compartment level, not tenancy level
- **Limited Permissions**: Requires only compartment-level IAM permissions (not tenancy administrator)
- **Targeted Access**: Policies are created per target compartment for granular control
- **Orchestrator Policies**: Orchestrator compartment policies are created at compartment level
- **No Tenancy-Wide Access**: Cannot grant tenancy-wide read access (limited to specified compartments)
