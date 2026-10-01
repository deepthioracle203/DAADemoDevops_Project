# DAA EBS and EPM IAM

This standalone configuration creates **6 compartments, 4 admin groups, and 4 policies**.

```text
Existing tenancy
├── DAA-EBS
│   ├── DAA-EBS-PROD
│   └── DAA-EBS-UAT
└── DAA-EPM
    ├── DAA-EPM-PROD
    └── DAA-EPM-UAT
```

Each child has an admin group named `<child>-ADMINS` and a policy named
`<child>-ADMIN-POLICY`. Each policy grants full administration only in that child
and its descendants, including resource deletion and local policy management.
Other existing policies may independently grant additional access. No parent-level
admin grants, users, or group memberships are created.

SANDBOX, FUSION, PRIMAVERA, shared services, and networking are not included.
Groups use tenancy-level OCI IAM, consistent with the earlier configurations.

## Files and inputs

`main.tf` creates the parents, children, groups, and policies. `provider.tf`
connects to OCI. `variables.tf` declares inputs. `outputs.tf` returns generated
OCIDs. `versions.tf` sets Terraform and provider versions.

Copy `terraform.tfvars.example` to `terraform.tfvars` only if that file does not
already exist. Replace just these two values:

| Input | Your value |
| --- | --- |
| `tenancy_ocid` | Full tenancy OCID starting with `ocid1.tenancy.` |
| `iam_home_region` | Actual tenancy home region, for example `eu-frankfurt-1` |

No existing parent compartment OCIDs are needed. Authentication must already be
configured separately using your local OCI configuration or Resource Manager.
Optional `freeform_tags` can retain their defaults.

## Run

Use a dedicated working directory for this project. Do not mix these files with
the earlier configuration: Terraform reads all `.tf` files in the working directory.
Copy the full project contents, including hidden CI/configuration files, into the
repository root if you want GitHub to run the supplied workflows.

```sh
cp terraform.tfvars.example terraform.tfvars
# Edit the two placeholder values before proceeding.
terraform init
terraform validate
terraform plan -out=iam.tfplan
# Review the plan, then apply when ready:
terraform apply iam.tfplan
```

For new resources, expect 14 additions: 6 compartments, 4 groups, 4 policies.
The two parent resources supply their generated IDs to the children, so Terraform
automatically creates parents before children. `enable_delete=false` preserves
compartments on destroy but also permits adoption of same-name compartments.

## If anything already exists

No state has been migrated from an earlier project. If any resources are already
managed by a previous Terraform configuration, reconcile ownership before applying
this one. Do not manage one resource from two states or discard existing state.
Import existing unowned resources by their OCIDs, for example:

```sh
terraform import 'oci_identity_compartment.parents["DAA-EBS"]' PARENT_OCID
terraform import 'oci_identity_compartment.children["DAA-EBS-PROD"]' CHILD_OCID
terraform import 'oci_identity_group.admins["DAA-EBS-PROD"]' GROUP_OCID
terraform import 'oci_identity_policy.admins["DAA-EBS-PROD"]' POLICY_OCID
```

## CI

The Terraform workflow checks formatting, validation, TFLint, and verified secrets.
It never applies infrastructure. The manual Sonar workflow requires `SONAR_TOKEN`
as a secret, `SONAR_HOST_URL` and `SONAR_PROJECT_KEY` as repository variables, and
`SONAR_ORGANIZATION` for SonarQube Cloud. CI workflows have not been run on GitHub.

Policy syntax: https://docs.oracle.com/en-us/iaas/Content/Identity/policysyntax/location.htm
