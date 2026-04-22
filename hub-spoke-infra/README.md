# hub-spoke-infra

Terraform project for a Hub-Spoke Azure architecture with AKS clusters and a site-to-site VPN to GPSSA on-premises environments.

---

## Architecture

```
Azure Environment
├── HUB VNet (10.0.0.0/16)
│   ├── AzureFirewallSubnet  (10.0.0.0/26)  → Azure Firewall
│   └── GatewaySubnet        (10.0.1.0/27)  → VPN Gateway
│
├── PROD PE VNet (10.1.0.0/16)
│   └── snet-aks-prod  →  AKS Cluster (prod)
│
├── STG PE VNet (10.2.0.0/16)
│   └── snet-aks-stg   →  AKS Cluster (stg)
│
└── DEV PE VNet (10.3.0.0/16)
    └── snet-aks-dev   →  AKS Cluster (dev)

GPSSA (On-Premises)
├── PROD segment  (192.168.10.0/24)
├── STG  segment  (192.168.20.0/24)
└── DEV  segment  (192.168.30.0/24)
```

All spoke egress is routed through the Hub Azure Firewall via UDR.
Each spoke peering uses `use_remote_gateways = true` so traffic to GPSSA transits the Hub VPN Gateway.

---

## Project Structure

```
hub-spoke-infra/
├── main.tf                        # Root: resource group + module calls
├── variables.tf                   # Root variables
├── outputs.tf                     # Root outputs
├── terraform.tfvars.example       # Copy → terraform.tfvars and fill in
│
├── modules/
│   ├── hub/                       # Hub VNet, Firewall, subnets
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpn/                       # VPN Gateway, Local GWs, connections
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── spokes/                    # Spoke VNets, peerings, route tables
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── aks/                       # AKS clusters (one per spoke)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    ├── prod/prod.tfvars            # Production-specific overrides
    ├── stg/stg.tfvars             # Staging-specific overrides
    └── dev/dev.tfvars             # Dev-specific overrides
```

---

## Prerequisites

- Terraform >= 1.5.0
- Azure CLI authenticated (`az login`)
- Contributor access on the target subscription

---

## Quickstart

### 1. Clone and configure

```bash
cd hub-spoke-infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:
- `gpssa_vpn_public_ip` — public IP of the GPSSA VPN device
- `gpssa_*_cidr` — on-premises CIDRs from the GPSSA team

### 2. Set the VPN pre-shared key via environment variable

```bash
export TF_VAR_vpn_shared_key="your-ipsec-preshared-key"
```

> Never commit the shared key to source control.

### 3. (Optional) Configure remote state backend

Uncomment and fill in the `backend "azurerm"` block in `main.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-tfstate"
  storage_account_name = "stgtfstate"
  container_name       = "tfstate"
  key                  = "hub-spoke-infra.tfstate"
}
```

### 4. Initialize and deploy

```bash
terraform init
terraform plan
terraform apply
```

> ⚠️ VPN Gateway provisioning takes ~30–45 minutes.

---

## Deploying with Environment Overrides

Apply environment-specific node counts or VM sizes without changing the base `terraform.tfvars`:

```bash
# Production
terraform apply -var-file="environments/prod/prod.tfvars"

# Staging
terraform apply -var-file="environments/stg/stg.tfvars"

# Dev
terraform apply -var-file="environments/dev/dev.tfvars"
```

---

## Key Outputs

| Output | Description |
|---|---|
| `vpn_gateway_public_ip` | Share with GPSSA team for tunnel setup |
| `firewall_private_ip` | Used internally by route tables |
| `aks_cluster_names` | Cluster names per environment |
| `aks_kube_configs` | Raw kubeconfigs (sensitive) |

Retrieve a kubeconfig after apply:

```bash
terraform output -raw aks_kube_configs | jq -r '.prod' > ~/.kube/prod-config
export KUBECONFIG=~/.kube/prod-config
kubectl get nodes
```

---

## Adding a New Spoke

Add an entry to the `spokes` variable in `terraform.tfvars`:

```hcl
spokes = {
  prod = { ... }
  stg  = { ... }
  dev  = { ... }
  uat  = {                          # ← new spoke
    vnet_cidr       = "10.4.0.0/16"
    aks_subnet_cidr = "10.4.0.0/22"
  }
}
```

Then add matching entries to `aks_node_counts` and `aks_vm_sizes`, and run `terraform apply`. No module changes needed.

---

## Notes

- AKS uses `outbound_type = "userDefinedRouting"` — all egress goes through the Hub Firewall. Ensure firewall rules allow required AKS egress before deploying clusters.
- `disable_bgp_route_propagation = true` on spoke route tables prevents the VPN gateway from overriding the UDR default route.
- The `hub_to_spoke` peerings use `allow_gateway_transit = true`; the `spoke_to_hub` peerings use `use_remote_gateways = true`. Both are required for VPN transit to work through the hub.
