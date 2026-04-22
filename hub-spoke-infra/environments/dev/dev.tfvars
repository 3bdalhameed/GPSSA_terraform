# environments/dev/dev.tfvars
# Use: terraform apply -var-file="environments/dev/dev.tfvars"

resource_group_name = "rg-hub-spoke-infra"
location            = "uaenorth"

tags = {
  project     = "hub-spoke-gpssa"
  managed_by  = "terraform"
  environment = "dev"
}

aks_node_counts = {
  prod = 3
  stg  = 2
  dev  = 2
}

aks_vm_sizes = {
  prod = "Standard_D4s_v5"
  stg  = "Standard_D2s_v5"
  dev  = "Standard_D2s_v5"
}
