subscription_id  = "079ab1f2-9528-44da-ba22-d60a88fdb0b8"
tenant_id        = "e994072b-523e-4bfe-86e2-442c5e10b244"
location         = "eastus"
global_prefix    = "eco"
environment_name = "dev"
image_tag        = "v0.1.0"

network_address_space        = ["10.20.0.0/16"]
containerapps_subnet_cidr    = "10.20.0.0/23"
log_analytics_retention_days = 30
acr_sku                      = "Standard"
caenv_internal_lb            = false

# AKS Configuration
kubernetes_version      = "1.31.2"
aks_node_count          = 2
aks_vm_size             = "Standard_B4ms"
aks_enable_auto_scaling = true
aks_min_count           = 1
aks_max_count           = 5
aks_subnet_cidr         = "10.20.2.0/24"
aks_service_cidr        = "10.0.0.0/16"
aks_dns_service_ip      = "10.0.0.10"

tags = {
  Project = "ecommerce-microservices"
  Owner   = "platform-team"
}

default_environment_variables = {
  SPRING_PROFILES_ACTIVE = "dev"
  CONFIG_SERVER_URL      = "https://cloud-config.dev.internal"
}

default_secrets = {}

service_definitions = {
  "api-gateway" = {
    repository     = "api-gateway"
    container_port = 8080
    ingress = {
      external_enabled = true
      target_port      = 8080
    }
  }

  "user-service" = {
    repository     = "user-service"
    container_port = 8700
    ingress = {
      external_enabled = false
      target_port      = 8700
    }
  }

  "product-service" = {
    repository     = "product-service"
    container_port = 8082
    ingress = {
      external_enabled = false
      target_port      = 8082
    }
  }

  "order-service" = {
    repository     = "order-service"
    container_port = 8083
    ingress = {
      external_enabled = false
      target_port      = 8083
    }
  }

  "payment-service" = {
    repository     = "payment-service"
    container_port = 8084
    ingress = {
      external_enabled = false
      target_port      = 8084
    }
  }

  "shipping-service" = {
    repository     = "shipping-service"
    container_port = 8085
    ingress = {
      external_enabled = false
      target_port      = 8085
    }
  }

  "favourite-service" = {
    repository     = "favourite-service"
    container_port = 8086
    ingress = {
      external_enabled = false
      target_port      = 8086
    }
  }

  "cloud-config" = {
    repository     = "cloud-config"
    container_port = 8888
    ingress = {
      external_enabled = false
      target_port      = 8888
    }
  }

  "service-discovery" = {
    repository     = "service-discovery"
    container_port = 8761
    ingress = {
      external_enabled = false
      target_port      = 8761
    }
  }
}
