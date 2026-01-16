# Upwind OCI Tenant Module

This module deploys Upwind's cloud security platform at the tenancy level in Oracle Cloud Infrastructure (OCI), providing tenancy-wide security scanning and monitoring across all compartments within a tenancy.

## Features

- **Tenancy-Wide Access**: Grants Upwind access to all compartments within the tenancy
- **Tenancy-Level Policies**: Creates policies at the tenancy level for maximum coverage
- **CloudScanner Integration**: Optional CloudScanner deployment for comprehensive security scanning
- **DSPM Scanning**: Optional Data Security Posture Management scanning
- **Workload Identity Federation**: Secure authentication with external identity providers
- **Fine-Grained Permissions**: Least-privilege access with tenancy-scoped policies
- **Multi-Tenant Support**: Support for multiple Upwind organizations

## Architecture

The module creates the following components:

1. **Shared IAM Module**: Establishes core identity and access management
2. **Tenancy Policies**: Grants access to all compartments within the tenancy
3. **CloudScanner Policies**: Optional policies for security scanning operations
4. **Asset Discovery**: Enables discovery of resources across the entire tenancy

## Usage

```hcl
module "upwind_tenant" {
  source = "./modules/tenant"

  # OCI Configuration
  oci_region                      = "us-ashburn-1"
  oci_tenancy_id                  = "ocid1.tenancy.oc1..xxxxx"
  upwind_orchestrator_compartment = "ocid1.compartment.oc1..xxxxx"

  # Upwind Configuration
  upwind_organization_id = "org_12345"
  upwind_client_id       = "your-client-id"
  upwind_client_secret   = "your-client-secret"

  # Workload Identity Federation (optional - has defaults)
  # root_level_compartment_id defaults to tenancy_id
  # oci_domain_id: if provided, uses existing domain; if not provided, creates new domain
  oci_domain_id = "ocid1.domain.oc1..xxxxx"  # Optional: use existing domain

  # Vault Configuration (optional)
  # If oci_vault_id is provided, secrets will be created in the existing vault
  # If oci_vault_key_id is not provided, a new key will be created in the existing vault
  oci_vault_id     = "ocid1.vault.oc1..xxxxx"  # Optional: use existing vault
  oci_vault_key_id = "ocid1.key.oc1..xxxxx"    # Optional: use existing key (or create new key in vault)

  # Optional Configuration
  enable_cloudscanners = true
  enable_dspm_scanning = true
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

- OCI Provider >= 5.0.0
- Terraform >= 1.0.0
- For vault operations: permissions to create vaults and keys (if `oci_vault_id` is not provided) or access to existing vault (if `oci_vault_id` is provided)
- For workload identity federation: permissions to create identity domains (if `oci_domain_id` is not provided) or access to existing identity domain (if `oci_domain_id` is provided)

## Resources Created

- Tenancy-Level IAM Policies (5+)
- Policy Attachments (3+)
- CloudScanner Policies (3+, if enabled)
- Shared IAM Module Resources (including vault, keys, and secrets)

## Security Model

- **Tenancy-Wide Access**: Policies grant access to all compartments within the tenancy
- **Least Privilege**: Minimal required permissions for each operation
- **Conditional Access**: CloudScanner policies include resource name conditions
- **Audit Trail**: All operations are logged and auditable
- **Encryption**: All secrets are encrypted using OCI Vault

## CloudScanner Features

When `enable_cloudscanners = true`, the module provides:

- **Compute Resource Discovery**: Read access to instances and volumes across all compartments
- **Boot Volume Management**: Create and delete boot volume backups
- **Object Storage Scanning**: Read access to buckets and objects
- **DSPM Integration**: Optional data security posture management

## DSPM Scanning

When `enable_dspm_scanning = true`, additional permissions are granted for:

- Object storage object reading across all compartments
- Enhanced data discovery capabilities
- Data classification and protection scanning

## Differences from Other Modules

The tenant module differs from other modules in that:

- **Tenancy-Wide Scope**: Policies are created at the tenancy level
- **Maximum Coverage**: Access to all compartments within the tenancy
- **Tenancy-Level Control**: Single point of control for the entire tenancy
- **Comprehensive Scanning**: Ability to scan all resources across the tenancy

## Use Cases

This module is ideal for:

- **Enterprise Organizations**: Large organizations with multiple compartments
- **Comprehensive Security**: Organizations requiring complete visibility
- **Centralized Management**: Organizations preferring centralized security management
- **Compliance Requirements**: Organizations with strict compliance requirements
