variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "kubernetes_version"  { type = string }
variable "tags"                { type = map(string) }

variable "spoke_subnet_ids" {
  description = "Map of environment name to AKS subnet ID"
  type        = map(string)
}

variable "aks_node_counts" {
  type = map(number)
}

variable "aks_vm_sizes" {
  type = map(string)
}
