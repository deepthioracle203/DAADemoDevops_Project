terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.0"
    }
  }
}

# Uses API-key credentials from the selected profile in your OCI config file.
provider "oci" {
  tenancy_ocid        = var.tenancy_ocid
  region              = var.region
  config_file_profile = var.oci_profile
}

variable "tenancy_ocid" {
  description = "Full OCID of the existing OCI tenancy."
  type        = string
  validation {
    condition     = startswith(var.tenancy_ocid, "ocid1.tenancy.")
    error_message = "Set tenancy_ocid to your full OCI tenancy OCID in terraform.tfvars."
  }
}

variable "region" {
  description = "OCI tenancy home region identifier."
  type        = string
}

variable "oci_profile" {
  description = "Named profile in your local OCI configuration file."
  type        = string
  default     = "DEFAULT"
}

# Source: DAA Tenancy Details.xlsx, Compartments and Groups sheets.
# This configuration assumes tenancy-level IAM groups. For groups in a specific
# Identity Domain, use oci_identity_domains_group with that domain's endpoint.
# Group creation alone grants no permissions; policies and memberships are separate.
locals {
  top_level_compartments = toset([
    "DAA-EBS", "DAA-EPM", "DAA-FUSION", "DAA-PRIMAVERA",
    "DAA-SHARED", "DAA-EXACC", "DAA-SANDBOX"
  ])

  child_compartments = {
    "DAA-EBS-PROD"        = "DAA-EBS"
    "DAA-EBS-UAT"         = "DAA-EBS"
    "DAA-EPM-PROD"        = "DAA-EPM"
    "DAA-EPM-UAT"         = "DAA-EPM"
    "DAA-FUSION-PROD"     = "DAA-FUSION"
    "DAA-FUSION-UAT"      = "DAA-FUSION"
    "DAA-PRIMAVERA-PROD"  = "DAA-PRIMAVERA"
    "DAA-PRIMAVERA-UAT"   = "DAA-PRIMAVERA"
    "DAA-SHARED-APP"      = "DAA-SHARED"
    "DAA-SHARED-SECURITY" = "DAA-SHARED"
    "DAA-SHARED-DATABASE" = "DAA-SHARED"
    "DAA-SHARED-O&M"      = "DAA-SHARED"
    "DAA-SHARED-NETWORK"  = "DAA-SHARED"
  }

  groups = {
    "DAA-TENANCY-ADMINS"        = "Overall tenancy administration, governance, and privileged administrative activities."
    "DAA-TERRAFORM-ADMINS"      = "Execute Terraform through OCI Resource Manager and provision approved IAM, governance, and infrastructure resources."
    "DAA-IDENTITY-ADMINS"       = "Manage Identity Domains, users, groups, SSO, federation, MFA, and identity configurations."
    "DAA-COST-ADMINS"           = "Manage budgets, cost analysis, usage reporting, subscription consumption, and cost governance."
    "DAA-APP-ADMINS"            = "Manage application infrastructure, Compute instances, Object Storage, and application-related resources."
    "DAA-SECURITY-ADMINS"       = "Manage security services such as Cloud Guard, Vault, keys, secrets, and security configurations."
    "DAA-DATABASE-ADMINS"       = "Manage OCI database resources and associated database services."
    "DAA-NETWORK-ADMINS"        = "Manage VCNs, subnets, route tables, gateways, NSGs, DRGs, and network connectivity."
    "DAA-OM-ADMINS"             = "Manage OCI Monitoring, Logging, Alarms, Notifications, and observability services."
    "DAA-EXACC-ADMINS"          = "Manage Exadata Cloud@Customer infrastructure and associated database resources."
    "DAA-EBS-PROD-ADMINS"       = "Administer Production EBS-related resources."
    "DAA-EBS-UAT-ADMINS"        = "Administer UAT EBS-related resources."
    "DAA-EPM-PROD-ADMINS"       = "Administer Production EPM-related resources."
    "DAA-EPM-UAT-ADMINS"        = "Administer UAT EPM-related resources."
    "DAA-FUSION-PROD-ADMINS"    = "Administer Production Fusion-related OCI resources and integrations."
    "DAA-FUSION-UAT-ADMINS"     = "Administer UAT Fusion-related OCI resources and integrations."
    "DAA-PRIMAVERA-PROD-ADMINS" = "Administer Production Primavera-related resources and integrations."
    "DAA-PRIMAVERA-UAT-ADMINS"  = "Administer UAT Primavera-related resources and integrations."
    "DAA-SANDBOX-ADMINS"        = "Manage temporary development, testing, PoC, and training resources within the sandbox."
    "DAA-AUDITORS"              = "Read/inspect tenancy resources for audit, security assessment, and governance purposes without modification privileges."
  }
}

resource "oci_identity_compartment" "top_level" {
  for_each       = local.top_level_compartments
  compartment_id = var.tenancy_ocid
  name           = each.value
  description    = "DAA managed compartment: ${each.value}"
  enable_delete  = false
}

resource "oci_identity_compartment" "child" {
  for_each       = local.child_compartments
  compartment_id = oci_identity_compartment.top_level[each.value].id
  name           = each.key
  description    = "DAA managed compartment: ${each.key}"
  enable_delete  = false
}

resource "oci_identity_group" "groups" {
  for_each       = local.groups
  compartment_id = var.tenancy_ocid
  name           = each.key
  description    = each.value
}

output "compartment_ocids" {
  description = "All 20 child compartments, keyed by their OCI display names."
  value = merge(
    { for name, compartment in oci_identity_compartment.top_level : name => compartment.id },
    { for name, compartment in oci_identity_compartment.child : name => compartment.id }
  )
}

output "group_ocids" {
  description = "All 20 tenancy-level IAM groups, keyed by their OCI names."
  value       = { for name, group in oci_identity_group.groups : name => group.id }
}
