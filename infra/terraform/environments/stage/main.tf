locals {
  name_prefix = format("%s-%s", var.global_prefix, var.environment_name)
  tags = merge(
    var.tags,
    {
      Environment = var.environment_name
    }
  )
}

module "resource_group" {
  source   = "../../modules/resource_group"
  name     = format("%s-rg", local.name_prefix)
  location = var.location
  tags     = local.tags
}

module "network" {
  source              = "../../modules/network"
  name                = format("%s-vnet", local.name_prefix)
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = var.network_address_space
  tags                = local.tags

  subnets = {
    aks = {
      name             = format("%s-aks-snet", local.name_prefix)
      address_prefixes = [var.aks_subnet_cidr]
    }
  }
}

module "log_analytics" {
  source              = "../../modules/log_analytics"
  name                = format("%s-law", local.name_prefix)
  resource_group_name = module.resource_group.name
  location            = var.location
  retention_in_days   = var.log_analytics_retention_days
  tags                = local.tags
}

module "aks" {
  source                     = "../../modules/aks"
  name                       = format("%s-aks", local.name_prefix)
  location                   = var.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = format("%s-aks", local.name_prefix)
  kubernetes_version         = var.kubernetes_version
  node_count                 = var.aks_node_count
  vm_size                    = var.aks_vm_size
  enable_auto_scaling        = var.aks_enable_auto_scaling
  min_node_count             = var.aks_min_count
  max_node_count             = var.aks_max_count
  subnet_id                  = module.network.subnet_ids["aks"]
  service_cidr               = var.aks_service_cidr
  dns_service_ip             = var.aks_dns_service_ip
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "pool2" {
  name                  = "pool2"
  kubernetes_cluster_id = module.aks.id
  vm_size               = "Standard_E2_v3"
  vnet_subnet_id        = module.network.subnet_ids["aks"]
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 3
  node_count            = 1
  mode                  = "User"
  tags                  = local.tags
}
