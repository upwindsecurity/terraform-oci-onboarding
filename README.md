# Terraform Module

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)](https://opensource.org/licenses/Apache-2.0)

A comprehensive Terraform module template repository with automated testing,
documentation generation, and release management.

## Modules

This repository contains the following Terraform modules:

- Root level - Main module with core functionality (switches between tenant and compartment deployment modes)
- Additional modules can be added to extend functionality

## Examples

Complete usage examples are available in the [examples](./examples/) directory:

- [examples/basic/](./examples/basic/) - Basic usage of the main module
- [examples/complete/](./examples/complete/) - Advanced configuration patterns with multiple module instances

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

We welcome contributions! Please see our [CONTRIBUTING.md](./CONTRIBUTING.md) guide for details on:

- Development setup and workflows
- Testing procedures
- Code standards and best practices
- How to add new submodules

For bug reports and feature requests, please use
[GitHub Issues](https://github.com/upwindsecurity/terraform-module/issues).

## Versioning

We use [Semantic Versioning](http://semver.org/) for releases. For the versions
available, see the [tags on this repository](https://github.com/upwindsecurity/terraform-module/tags).

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## Support

- [Documentation](https://docs.upwind.io)
- [Issues](https://github.com/upwindsecurity/terraform-module/issues)
- [Contributing Guide](./CONTRIBUTING.md)
