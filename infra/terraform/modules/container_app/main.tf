locals {
  rendered_memory = format("%sGi", var.memory_gb)
}

resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  container_app_environment_id = var.environment_id
  revision_mode                = var.revision_mode
  tags                         = var.tags

  registry {
    server                = var.registry_server
    username              = var.registry_username
    password_secret_name  = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = var.registry_password
  }

  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  template {
    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = local.rendered_memory

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    scale {
      min_replicas = var.min_replicas
      max_replicas = var.max_replicas
    }
  }

  dynamic "ingress" {
    for_each = var.ingress == null ? [] : [var.ingress]
    content {
      external_enabled           = ingress.value.external_enabled
      target_port                = ingress.value.target_port
      transport                  = coalesce(ingress.value.transport, "auto")
      allow_insecure_connections = coalesce(ingress.value.allow_insecure_connections, false)
    }
  }
}
