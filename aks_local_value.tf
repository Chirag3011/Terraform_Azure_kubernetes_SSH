locals {
  ssh_key_name = "sshbelovedalien"
  ak8s = {
    "aks_01" = {
      rg_name        = "chirag"
      rg_location    = "centralIndia"
      aksvnet_name   = "orchestrator_vnet"
      akssubnet_name = "orchestrator_subnet"
    }
  }
}
