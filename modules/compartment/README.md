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
  # create_identity_domain defaults to true

  # Optional Configuration
  enable_cloudscanners = true
  enable_dspm_scanning = true
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

- OCI Provider >= 5.0.0
- Terraform >= 1.0.0
- Existing Vault and Vault Key in OCI
- Appropriate IAM permissions to create policies in target compartments
- Target compartments must exist

## Resources Created

- IAM Policies (3+ per target compartment)
- Policy Attachments (3+ per target compartment)
- CloudScanner Policies (3+ per target compartment, if enabled)
- Shared IAM Module Resources

## Security Model

- **Compartment Isolation**: Policies are created directly in target compartments
- **Least Privilege**: Minimal required permissions for each operation
- **Conditional Access**: CloudScanner policies include resource name conditions
- **Audit Trail**: All operations are logged and auditable
- **Encryption**: All secrets are encrypted using OCI Vault

## CloudScanner Features

When `enable_cloudscanners = true`, the module provides:

- **Compute Resource Discovery**: Read access to instances and volumes
- **Boot Volume Management**: Create and delete boot volume backups
- **Object Storage Scanning**: Read access to buckets and objects
- **DSPM Integration**: Optional data security posture management

## DSPM Scanning

When `enable_dspm_scanning = true`, additional permissions are granted for:

- Object storage object reading
- Enhanced data discovery capabilities
- Data classification and protection scanning

## Differences from Tenant Module

The compartment module differs from the tenant module in that:

- **Compartment-Level Scope**: Policies are created at the compartment level, not tenancy level
- **Limited Permissions**: Requires only compartment-level IAM permissions (not tenancy administrator)
- **Targeted Access**: Policies are created per target compartment for granular control
- **Orchestrator Policies**: Orchestrator compartment policies are created at compartment level
- **No Tenancy-Wide Access**: Cannot grant tenancy-wide read access (limited to specified compartments)
