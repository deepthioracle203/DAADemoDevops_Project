variable "tenancy_ocid" {
  description = "Full OCID of the existing OCI tenancy. The parents are created here."
  type        = string

  validation {
    condition     = startswith(var.tenancy_ocid, "ocid1.tenancy.")
    error_message = "Replace tenancy_ocid with your full OCI tenancy OCID."
  }
}

variable "iam_home_region" {
  description = "Home region of your tenancy, for example eu-frankfurt-1."
  type        = string

  validation {
    condition     = length(trimspace(var.iam_home_region)) > 0 && !startswith(var.iam_home_region, "REPLACE_")
    error_message = "Replace iam_home_region with the actual tenancy home region."
  }
}

variable "freeform_tags" {
  description = "Optional tags applied to the created resources."
  type        = map(string)
  default = {
    project = "daa-oracle-oci-infrastructure"
    managed = "terraform"
  }
}
