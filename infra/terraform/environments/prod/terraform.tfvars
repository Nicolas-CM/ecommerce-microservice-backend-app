subscription_id  = "079ab1f2-9528-44da-ba22-d60a88fdb0b8"
tenant_id        = "e994072b-523e-4bfe-86e2-442c5e10b244"
location         = "centralus"
global_prefix    = "eco"
environment_name = "prod"
image_tag        = "v1.0.0"

network_address_space        = ["10.40.0.0/16"]
containerapps_subnet_cidr    = "10.40.1.0/24"
log_analytics_retention_days = 120
acr_sku                      = "Premium"
caenv_internal_lb            = true

tags = {
  Project = "ecommerce-microservices"
  Owner   = "platform-team"
  Tier    = "production"
}

default_environment_variables = {
  SPRING_PROFILES_ACTIVE = "prod"
  CONFIG_SERVER_URL      = "https://cloud-config.prod.internal"
}

default_secrets = {
  DATABASE_URL = "kv://prod-db-url"
}

service_definitions = {
  "api-gateway" = {
    repository     = "api-gateway"
    container_port = 8080
    ingress = {
      external_enabled = true
      target_port      = 8080
    }
    min_replicas = 3
    max_replicas = 6
    cpu          = 1
    memory_gb    = 2
  }

  "user-service" = {
    repository     = "user-service"
    container_port = 8081
    ingress = {
      external_enabled = false
      target_port      = 8081
    }
    min_replicas = 3
    max_replicas = 6
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
