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

## Resources Created

- Dynamic Groups (1-2): Management dynamic group (always), CloudScanner dynamic group (if `enable_cloudscanners = true`)
- Users (1-2): Management user (always), CloudScanner user (if `enable_cloudscanners = true`)
- IAM Policies (4): Orchestrator compartment policies for CloudScanner (3), Workload Identity Federation policy (1)
- Identity Domain (0-1): Created if `create_identity_domain = true`
- Workload Identity Federation Policy (1): AWS workload federation policy

Note: Vault and secret resources are currently commented out and not created by this module. Secrets should be managed externally or through a separate module.

## Security Considerations

- Dynamic groups use least-privilege access principles
- Policies are scoped to specific compartments
- Workload identity federation provides secure external authentication via OIDC
- Resource naming includes organization ID for multi-tenant support
- Identity domain supports secure federation with external identity providers (e.g., AWS IAM)
