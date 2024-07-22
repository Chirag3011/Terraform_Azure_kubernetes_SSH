terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.aksvnet_name
  resource_group_name = var.rg_name
  location            = var.rg_location
  address_space       = ["10.5.0.0/16"]

  tags = {
    owner = "chirag"
  }
}

resource "azurerm_subnet" "vnet_subnet_01" {
  name                 = var.akssubnet_name
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.5.1.0/24"]
}


resource "azurerm_network_security_group" "nsg" {
  name                = "ochectrator_nsg"
  location            = var.rg_location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "allow_all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    owner = "chirag"
  }
}


resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.vnet_subnet_01.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

# resource "azurerm_private_dns_zone" "aks-dns" {
#   name                = "privatelink.eastus2.azmk8s.io"
#   resource_group_name = var.rg_name
# }

# resource "azurerm_user_assigned_identity" "aks-identity" {
#   name                = "aks-dns-identity"
#   resource_group_name = var.rg_name
#   location            = var.rg_location
# }

# resource "azurerm_role_assignment" "aks-role-assignment" {
#   scope                = azurerm_private_dns_zone.aks-dns.id
#   role_definition_name = "Private DNS Zone Contributor"
#   principal_id         = azurerm_user_assigned_identity.aks-identity.principal_id
# }



#defining data sourcing

data "azapi_resource" "ssh_public_key" {
  name      = var.ssh_key_name
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  parent_id = "/subscriptions/0b1f7848-73ed-4735-80dd-f82f674f942d/resourceGroups/chirag/"
}

data "azapi_resource_action" "ssh_public_key_gen" {
  type                   = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id            = data.azapi_resource.ssh_public_key.id
  action                 = "generateKeyPair"
  method                 = "POST"
  response_export_values = ["publicKey", "privateKey"]
}


resource "azurerm_kubernetes_cluster" "orchestrator" {
  name                    = "container-orchestrator"
  location                = var.rg_location
  resource_group_name     = var.rg_name
  dns_prefix              = random_pet.azurerm_kubernetes_cluster_dns_prefix.id
  private_cluster_enabled = true
  # private_dns_zone_id     = azurerm_private_dns_zone.aks-dns.id

  default_node_pool {
    name           = "agentpool"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.vnet_subnet_01.id
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = "kubeadmin"
    ssh_key {
      key_data = data.azapi_resource_action.ssh_public_key_gen.output.key_data
    }
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    # outbound_type  = "userDefinedRouting"
    ip_versions = ["IPv4"]
  }

  tags = {
    owner = "chirag"
  }
}


output "client_certificate" {
  value     = azurerm_kubernetes_cluster.orchestrator.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.orchestrator.kube_config_raw
  sensitive = true
}

output "cluster_username" {
  value     = azurerm_kubernetes_cluster.orchestrator.kube_config[0].username
  sensitive = true
}

output "cluster_password" {
  value     = azurerm_kubernetes_cluster.orchestrator.kube_config[0].password
  sensitive = true
}
