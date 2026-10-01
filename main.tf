locals {
  # These two parents will be created directly under your tenancy.
  parents = toset(["DAA-EBS", "DAA-EPM"])

  # Left = child compartment name. Right = parent compartment name.
  children = {
    "DAA-EBS-PROD" = "DAA-EBS"
    "DAA-EBS-UAT"  = "DAA-EBS"
    "DAA-EPM-PROD" = "DAA-EPM"
    "DAA-EPM-UAT"  = "DAA-EPM"
  }
}

# 1. Create the two parents. You do not need existing parent OCIDs.
resource "oci_identity_compartment" "parents" {
  for_each       = local.parents
  compartment_id = var.tenancy_ocid
  name           = each.value
  description    = "DAA application parent: ${each.value}"
  enable_delete  = false
  freeform_tags  = var.freeform_tags
}

# 2. Create PROD and UAT inside each new parent.
# Terraform uses each parent's generated ID and creates the parents first.
resource "oci_identity_compartment" "children" {
  for_each       = local.children
  compartment_id = oci_identity_compartment.parents[each.value].id
  name           = each.key
  description    = "DAA environment compartment: ${each.key}"
  enable_delete  = false
  freeform_tags  = var.freeform_tags
}

# 3. Create one admin group for each child compartment.
# Example: DAA-EBS-PROD-ADMINS. Users must be added to groups separately.
resource "oci_identity_group" "admins" {
  for_each       = local.children
  compartment_id = var.tenancy_ocid
  name           = "${each.key}-ADMINS"
  description    = "Administer resources within ${each.key}."
  freeform_tags  = var.freeform_tags
}

# 4. Give each group full administration in its own child compartment.
# This includes resource deletion and local policy management, plus access to
# descendants. No access to the parent or sibling PROD/UAT compartment is granted.
resource "oci_identity_policy" "admins" {
  for_each       = local.children
  compartment_id = oci_identity_compartment.children[each.key].id
  name           = "${each.key}-ADMIN-POLICY"
  description    = "Allow ${each.key}-ADMINS to administer ${each.key}."
  statements = [
    "Allow group id ${oci_identity_group.admins[each.key].id} to manage all-resources in compartment id ${oci_identity_compartment.children[each.key].id}"
  ]
  freeform_tags = var.freeform_tags
}
