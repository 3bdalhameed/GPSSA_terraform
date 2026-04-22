# environments/prod/prod.tfvars
# Use: terraform apply -var-file="environments/prod/prod.tfvars"

resource_group_name = "rg-hub-spoke-infra"
location            = "uaenorth"

tags = {
  project     = "hub-spoke-gpssa"
  managed_by  = "terraform"
  environment = "prod"
}

aks_node_counts = {
  prod = 5
  stg  = 2
  dev  = 1
}

aks_vm_sizes = {
  prod = "Standard_D8s_v5"
  stg  = "Standard_D2s_v5"
  dev  = "Standard_B2s"
}
