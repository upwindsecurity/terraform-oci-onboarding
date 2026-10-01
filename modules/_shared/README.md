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

### Identity domain replication permission

The management group (`upwind-federated-mgmt-*`) is granted one domain statement, in the
`federated-mgmt-group-domain-replication-<suffix>` policy:

```
Allow group id <mgmt group> to manage domains in tenancy
  where all { target.domain.id = '<Upwind identity domain OCID>', request.permission = 'DOMAIN_REPLICATE' }
```

Compartment mode attaches it to the domain's compartment instead, and adds `inspect domains` there so
onboarding-service can find the domain. Tenant mode already has that through `read all-resources in tenancy`.

**Why it's needed.** Users and policies in a secondary identity domain only work in the regions the domain
is replicated to. Oracle replicates one region at a time with long queue gaps, around 25 minutes a region,
so replicating inside `terraform apply` outlasted the one-hour OCI session token on tenancies with several
regions. The apply now only grants this permission. Upwind's onboarding-service requests replication
to each subscribed region after onboarding, and to any region subscribed later.

**What the conditions do.** `manage domains` on its own would cover every identity domain in scope,
including the tenancy's Default domain, and every domain operation. Both conditions are required:

- `target.domain.id` limits it to the Upwind identity domain the module created.
- `request.permission = 'DOMAIN_REPLICATE'` limits it to adding replicas. It can't update, deactivate,
  delete or move the domain. Oracle has no API to remove a replica.
- `where all` means both must hold. `where any` would grant either on its own.

**Scope.** The policy is only created when this module creates the domain. A domain passed in with
`oci_domain_id` belongs to the customer and isn't replicated by Upwind.

**Guarded.** A precondition on the policy fails `terraform plan` if a `manage domains` statement loses
either condition or `where all`, or if the policy isn't attached to the domain's compartment.
`iam/tests/domain_replication_policy.tftest.hcl` pins the statements and their attachment, and runs in CI.

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
