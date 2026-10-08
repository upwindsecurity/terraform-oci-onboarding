# Basic Example

Onboards an entire OCI tenancy to Upwind through the root module in `tenant` mode, with only the required inputs set.
CloudScanners are left off; see the [complete example](../complete/) to enable them.

Apply from the tenancy's home region: OCI accepts writes to users, groups, dynamic groups and policies only there.

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
| <a name="input_oci_tenancy_id"></a> [oci\_tenancy\_id](#input\_oci\_tenancy\_id) | The OCI tenancy ID. | `string` | n/a | yes |
| <a name="input_upwind_client_id"></a> [upwind\_client\_id](#input\_upwind\_client\_id) | The client ID used for authentication with the Upwind Authorization Service. | `string` | n/a | yes |
| <a name="input_upwind_client_secret"></a> [upwind\_client\_secret](#input\_upwind\_client\_secret) | The client secret for authentication with the Upwind Authorization Service. | `string` | n/a | yes |
| <a name="input_upwind_orchestrator_compartment"></a> [upwind\_orchestrator\_compartment](#input\_upwind\_orchestrator\_compartment) | The OCID of the compartment where Upwind resources are created. | `string` | n/a | yes |
| <a name="input_upwind_organization_id"></a> [upwind\_organization\_id](#input\_upwind\_organization\_id) | The Upwind organization ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_deployment_mode"></a> [deployment\_mode](#output\_deployment\_mode) | The deployment mode used |
| <a name="output_oci_tenancy_id"></a> [oci\_tenancy\_id](#output\_oci\_tenancy\_id) | The onboarded OCI tenancy ID |
| <a name="output_upwind_management_service_account_email"></a> [upwind\_management\_service\_account\_email](#output\_upwind\_management\_service\_account\_email) | Email of the management service account |
| <a name="output_vault_id"></a> [vault\_id](#output\_vault\_id) | The OCID of the Vault holding the Upwind credentials |
<!-- END_TF_DOCS -->
