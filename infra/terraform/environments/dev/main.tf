terraform {
  required_version = ">= 1.7.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  backend "azurerm" {
    # Backend configuration is provided via backend.hcl file
    # Run: terraform init -backend-config=backend.hcl
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

locals {
  name_prefix = format("%s-%s", var.global_prefix, var.environment_name)
  tags = merge(
    var.tags,
    {
      Environment = var.environment_name
    }
  )

  normalized_services = {
    for service_name, service in var.service_definitions :
    service_name => {
      image = coalesce(
        lookup(service, "image", null),
        format(
          "%s/%s:%s",
          module.acr.login_server,
          coalesce(lookup(service, "repository", null), service_name),
          var.image_tag
        )
      )
      container_port = lookup(service, "container_port", 8080)
      cpu            = lookup(service, "cpu", 0.5)
      memory_gb      = lookup(service, "memory_gb", 1)
      ingress        = lookup(service, "ingress", null)
      env            = lookup(service, "env", {})
      secrets        = lookup(service, "secrets", {})
      min_replicas   = lookup(service, "min_replicas", 1)
      max_replicas   = lookup(service, "max_replicas", 2)
    }
  }
}

module "resource_group" {
  source  = "../../modules/resource_group"
  name    = format("%s-rg", local.name_prefix)
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
    containerapps = {
      name             = format("%s-apps-snet", local.name_prefix)
      address_prefixes = [var.containerapps_subnet_cidr]
      service_delegation = {
        name = "Microsoft.App/environments"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
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

module "acr" {
  source              = "../../modules/acr"
  name                = format("%sacr", replace(local.name_prefix, "-", ""))
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = var.acr_sku
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
  acr_id                     = module.acr.id
  tags                       = local.tags
}

module "container_apps_env" {
  source                       = "../../modules/container_apps_env"
  name                         = format("%s-aca-env", local.name_prefix)
  resource_group_name          = module.resource_group.name
  location                     = var.location
  log_analytics_workspace_id   = module.log_analytics.id
  infrastructure_subnet_id     = module.network.subnet_ids["containerapps"]
  internal_load_balancer_enabled = var.caenv_internal_lb
  tags                         = local.tags
}

module "container_apps" {
  for_each = local.normalized_services
  source   = "../../modules/container_app"

  name                 = format("%s-%s", local.name_prefix, each.key)
  resource_group_name  = module.resource_group.name
  location             = var.location
  environment_id       = module.container_apps_env.id
  image                = each.value.image
  registry_server      = module.acr.login_server
  registry_username    = module.acr.admin_username
  registry_password    = module.acr.admin_password
  cpu                  = each.value.cpu
  memory_gb            = each.value.memory_gb
  environment_variables = merge(var.default_environment_variables, each.value.env)
  secrets              = merge(var.default_secrets, each.value.secrets)
  min_replicas         = each.value.min_replicas
  max_replicas         = each.value.max_replicas
  ingress = each.value.ingress == null ? null : merge(
    {
      transport                  = "auto"
      allow_insecure_connections = false
    },
    each.value.ingress
  )
  tags = local.tags
}
