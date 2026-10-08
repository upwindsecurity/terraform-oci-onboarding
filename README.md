# Upwind OCI Onboarding

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)](https://opensource.org/licenses/Apache-2.0)

Terraform module that connects an Oracle Cloud Infrastructure (OCI) tenancy, or selected compartments in it, to
[Upwind](https://www.upwind.io). It creates the IAM users, groups, dynamic groups and policies Upwind needs, an identity
domain with workload identity federation, and a Vault holding the Upwind credentials. It can also deploy Upwind
CloudScanners, with optional DSPM scanning.

## Deployment modes

The root module switches between two submodules with `deployment_mode`:

- `tenant` (default): grants Upwind access across the whole tenancy. Set `upwind_orchestrator_compartment` to the
  compartment that holds Upwind's own resources.
- `compartment`: grants Upwind access only to `target_compartment_ids`. Set `upwind_orchestrator_compartment_id`.
  The CloudScanner dynamic group and the Upwind IAM users are still created at the tenancy root, so the caller needs
  tenancy-level `manage dynamic-groups` and `manage users`.

In both modes, apply from the tenancy's home region: OCI accepts writes to users, groups, dynamic groups and policies
only there.

## Usage

```hcl
module "upwind_onboarding" {
  source = "git::https://github.com/upwindsecurity/terraform-oci-onboarding.git?ref=vX.Y.Z"

  deployment_mode = "tenant"

  upwind_organization_id = "org_xxxxxxxx"
  upwind_client_id       = var.upwind_client_id
  upwind_client_secret   = var.upwind_client_secret

  oci_tenancy_id                  = "ocid1.tenancy.oc1..xxxx"
  upwind_orchestrator_compartment = "ocid1.compartment.oc1..xxxx"
}
```

Replace `vX.Y.Z` with a release from the [tags](https://github.com/upwindsecurity/terraform-oci-onboarding/tags).
The supported Terraform and provider versions are in [versions.tf](./versions.tf).

Before applying, `upwindctl oracle onboarding preflight` checks the tenancy, the caller's permissions and the inputs,
so a problem is reported before Terraform creates anything.

## Examples

- [examples/basic/](./examples/basic/) - tenant mode through the root module, required inputs only
- [examples/complete/](./examples/complete/) - compartment mode through the root module, with CloudScanners and DSPM
- [examples/tenant/](./examples/tenant/) - the `tenant` submodule used directly
- [examples/compartment/](./examples/compartment/) - the `compartment` submodule used directly

## Offboarding

`terraform destroy` removes everything this module created. If the module also created the identity
domain (`oci_domain_id` not set, the default), the destroy needs one manual step in the middle:

- OCI only deletes an identity domain once it has been **deactivated**, and only deactivates it once
  every app inside it is deactivated or gone.
- The OCI provider deletes the domain without deactivating it first.
- Terraform deletes everything *inside* the domain first (the Upwind OAuth app, users, groups and
  token-exchange trust), then the domain. So the first destroy removes all of that, then stops at the
  domain.

Run these with the same OCI credentials you used to apply:

```sh
# 1. Destroy. It removes everything except the identity domain, then fails on the domain.
terraform destroy

# 2. Deactivate the domain. This reads its OCID from state, so it works whatever outputs your
#    configuration declares. Our OAuth app is already gone, so OCI accepts the deactivation.
DOMAIN_ID=$(terraform state show -no-color "$(terraform state list | grep 'oci_identity_domain.upwind_identity_domain\[0\]')" \
  | awk -F'"' '/^ *id *=/ {print $2; exit}')
oci iam domain deactivate --domain-id "$DOMAIN_ID"

# 3. Destroy again. It deletes the now-inactive domain.
terraform destroy
```

Notes:

- **Replicas don't need removing.** Deleting the domain removes it from every region it was
  replicated to. OCI has no API to remove a replica on its own.
- **Getting the OCID another way:** if your configuration exposes this module's
  `identity_domain_id` output, `terraform output -raw identity_domain_id` gives the same OCID. Read it
  **before** step 1, because a partly completed destroy can leave outputs unreadable.
- **A customer-supplied domain (`oci_domain_id`) is not deleted.** When
  `identity_domain_created_by_module` is `false`, step 1 removes Upwind's users, groups and OAuth app
  from your domain and the destroy completes, so steps 2 and 3 aren't needed.
- **Upwind loses access as soon as step 1 starts.** That's expected when offboarding.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development setup, testing and code standards. Report bugs and request
features through [GitHub Issues](https://github.com/upwindsecurity/terraform-oci-onboarding/issues).

## Versioning

Releases follow [Semantic Versioning](http://semver.org/) and are published as
[tags on this repository](https://github.com/upwindsecurity/terraform-oci-onboarding/tags).

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## Support

- [Documentation](https://docs.upwind.io)
- [Issues](https://github.com/upwindsecurity/terraform-oci-onboarding/issues)
