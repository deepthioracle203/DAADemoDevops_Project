# For local runs, configure API-key credentials in your OCI config file.
# In OCI Resource Manager, use its supplied authentication.
provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = var.iam_home_region
}
