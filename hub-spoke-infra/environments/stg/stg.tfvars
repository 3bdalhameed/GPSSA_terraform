# environments/stg/stg.tfvars
# Use: terraform apply -var-file="environments/stg/stg.tfvars"

resource_group_name = "rg-hub-spoke-infra"
location            = "uaenorth"

tags = {
  project     = "hub-spoke-gpssa"
  managed_by  = "terraform"
  environment = "stg"
}

aks_node_counts = {
  prod = 3
  stg  = 3
  dev  = 1
}

aks_vm_sizes = {
  prod = "Standard_D4s_v5"
  stg  = "Standard_D4s_v5"
  dev  = "Standard_B2s"
}
