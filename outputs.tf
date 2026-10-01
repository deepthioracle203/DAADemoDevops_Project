output "parent_compartment_ocids" {
  description = "IDs of the two parent compartments created by this script."
  value       = { for name, compartment in oci_identity_compartment.parents : name => compartment.id }
}

output "child_compartment_ocids" {
  description = "IDs of the four PROD/UAT child compartments."
  value       = { for name, compartment in oci_identity_compartment.children : name => compartment.id }
}

output "group_ocids" {
  description = "Admin group IDs, keyed by their child compartment names."
  value       = { for name, group in oci_identity_group.admins : name => group.id }
}

output "policy_ocids" {
  description = "Policy IDs, keyed by their child compartment names."
  value       = { for name, policy in oci_identity_policy.admins : name => policy.id }
}
