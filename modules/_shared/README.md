# Upwind OCI Shared Modules

This directory contains shared modules for Upwind's Oracle Cloud Infrastructure (OCI) integration.

## Modules

### IAM Module (`iam/`)

The IAM module provides shared identity and access management resources including:

- Dynamic Groups for service-to-service authentication
- Users for human access
- IAM Policies for fine-grained permissions
- Workload Identity Federation for AWS authentication via OCI Identity Domain

This module is used by all other Upwind modules to establish consistent IAM patterns across the platform.

## Usage

The shared modules are designed to be consumed by the main Upwind modules:

- `tenant/` - Tenant-level (tenancy-wide) deployment
- `compartment/` - Compartment-level deployment

Each main module will call the shared IAM module to establish the necessary identity and access management foundation.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│     Tenant      │    │   Compartment   │
│     Module      │    │     Module      │
│  (Tenancy-wide) │    │ (Compartment)   │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────────────────┘
                    │
        ┌───────────▼────────────┐
        │    Shared IAM Module   │
        │  - Dynamic Groups      │
        │  - Users               │
        │  - Policies            │
        │  - Identity Domain     │
        │  - WIF Policy          │
        └────────────────────────┘
```

## Security Model

The shared modules implement a comprehensive security model:

1. **Least Privilege**: All policies grant minimal required permissions
2. **Compartment Isolation**: Resources are scoped to specific compartments
3. **Workload Identity Federation**: Secure authentication via OCI Identity Domain and OIDC
4. **Audit Trail**: All operations are logged and auditable
5. **Multi-Tenant**: Support for multiple Upwind organizations

## Requirements

- OCI Provider >= 7.0.0
- Terraform >= 1.0.0
- Appropriate IAM permissions to create dynamic groups, users, and policies
- For workload identity federation: permissions to create identity domains (if `create_identity_domain = true`) or access to existing identity domain
