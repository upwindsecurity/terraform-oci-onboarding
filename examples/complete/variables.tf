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

variable "upwind_region" {
  description = "The region of the Upwind organization."
  type        = string
  default     = "us"
}

# Required OCI configuration
variable "oci_tenancy_id" {
  description = "The OCI tenancy ID."
  type        = string
}

variable "oci_region" {
  description = "The OCI region where resources are created. IAM resources can only be written in the tenancy's home region."
  type        = string
}

variable "upwind_orchestrator_compartment_id" {
  description = "The OCID of the compartment where Upwind resources are created."
  type        = string
}

variable "target_compartment_ids" {
  description = "The OCIDs of the compartments Upwind is granted access to."
  type        = list(string)
}

# CloudScanners
variable "scanner_client_id" {
  description = "The client ID used for authentication with the Upwind Cloudscanner Service."
  type        = string
}

variable "scanner_client_secret" {
  description = "The client secret for authentication with the Upwind Cloudscanner Service."
  type        = string
  sensitive   = true
}

# Naming and tags
variable "resource_suffix" {
  description = "A suffix to append to resource names to ensure uniqueness."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of freeform tags to apply to all resources."
  type        = map(string)
  default     = {}
}
