# Required Upwind configuration
variable "upwind_organization_id" {
  description = "The Upwind organization ID."
  type        = string
}

variable "upwind_client_id" {
  description = "The client ID used for authentication with the Upwind Authorization Service."
  type        = string
}

variable "upwind_client_secret" {
  description = "The client secret for authentication with the Upwind Authorization Service."
  type        = string
  sensitive   = true
}

# Required OCI configuration
variable "oci_tenancy_id" {
  description = "The OCI tenancy ID."
  type        = string
}

variable "upwind_orchestrator_compartment" {
  description = "The OCID of the compartment where Upwind resources are created."
  type        = string
}
