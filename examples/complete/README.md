# Complete Example

Onboards selected OCI compartments to Upwind through the root module in `compartment` mode, with CloudScanners and
DSPM scanning enabled, a resource suffix and freeform tags.

Compartment mode still creates the CloudScanner dynamic group and the Upwind IAM users at the tenancy root, so the
caller needs tenancy-level `manage dynamic-groups` and `manage users`. Apply from the tenancy's home region.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 8.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_upwind_onboarding"></a> [upwind\_onboarding](#module\_upwind\_onboarding) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_oci_region"></a> [oci\_region](#input\_oci\_region) | The OCI region where resources are created. IAM resources can only be written in the tenancy's home region. | `string` | n/a | yes |
| <a name="input_oci_tenancy_id"></a> [oci\_tenancy\_id](#input\_oci\_tenancy\_id) | The OCI tenancy ID. | `string` | n/a | yes |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | A suffix to append to resource names to ensure uniqueness. | `string` | `""` | no |
| <a name="input_scanner_client_id"></a> [scanner\_client\_id](#input\_scanner\_client\_id) | The client ID used for authentication with the Upwind Cloudscanner Service. | `string` | n/a | yes |
| <a name="input_scanner_client_secret"></a> [scanner\_client\_secret](#input\_scanner\_client\_secret) | The client secret for authentication with the Upwind Cloudscanner Service. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of freeform tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_target_compartment_ids"></a> [target\_compartment\_ids](#input\_target\_compartment\_ids) | The OCIDs of the compartments Upwind is granted access to. | `list(string)` | n/a | yes |
| <a name="input_upwind_client_id"></a> [upwind\_client\_id](#input\_upwind\_client\_id) | The client ID used for authentication with the Upwind Authorization Service. | `string` | n/a | yes |
| <a name="input_upwind_client_secret"></a> [upwind\_client\_secret](#input\_upwind\_client\_secret) | The client secret for authentication with the Upwind Authorization Service. | `string` | n/a | yes |
| <a name="input_upwind_orchestrator_compartment_id"></a> [upwind\_orchestrator\_compartment\_id](#input\_upwind\_orchestrator\_compartment\_id) | The OCID of the compartment where Upwind resources are created. | `string` | n/a | yes |
| <a name="input_upwind_organization_id"></a> [upwind\_organization\_id](#input\_upwind\_organization\_id) | The Upwind organization ID. | `string` | n/a | yes |
| <a name="input_upwind_region"></a> [upwind\_region](#input\_upwind\_region) | The region of the Upwind organization. | `string` | `"us"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_configuration"></a> [configuration](#output\_configuration) | Module configuration details |
| <a name="output_deployment_mode"></a> [deployment\_mode](#output\_deployment\_mode) | The deployment mode used |
| <a name="output_identity_domain_oidc_issuer_url"></a> [identity\_domain\_oidc\_issuer\_url](#output\_identity\_domain\_oidc\_issuer\_url) | OIDC issuer URL for the Identity Domain |
| <a name="output_target_compartment_ids"></a> [target\_compartment\_ids](#output\_target\_compartment\_ids) | The compartments Upwind was granted access to |
| <a name="output_upwind_management_service_account_email"></a> [upwind\_management\_service\_account\_email](#output\_upwind\_management\_service\_account\_email) | Email of the management service account |
| <a name="output_vault_id"></a> [vault\_id](#output\_vault\_id) | The OCID of the Vault holding the Upwind credentials |
<!-- END_TF_DOCS -->
