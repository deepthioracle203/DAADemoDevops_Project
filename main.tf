terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
  }
}

# OCI Provider
# In OCI DevOps, authentication can use Resource Principal.
provider "oci" {
  region              = var.region
  auth                = "ResourcePrincipal"
}

variable "region" {
  description = "OCI Region"
  type        = string
  default     = "eu-frankfurt-1"
}

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

# Create OCI Compartment
resource "oci_identity_compartment" "dev_compartment" {
  compartment_id = var.tenancy_ocid
  name           = "DEV"
  description    = "Development compartment provisioned by Terraform via OCI DevOps"

  enable_delete = true

  freeform_tags = {
    "ManagedBy"   = "Terraform"
    "Environment" = "Development"
  }
}
