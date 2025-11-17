project_id        = "eco-microservices-dev"
region            = "us-central1"
global_prefix     = "eco"
environment_name  = "dev"
image_tag         = "v0.1.0"
subnet_cidr_block = "10.60.1.0/24"

labels = {
  project = "ecommerce-microservices"
  owner   = "platform-team"
}

default_environment_variables = {
  SPRING_PROFILES_ACTIVE = "dev"
  CONFIG_SERVER_URL      = "https://cloud-config.dev.internal"
}

default_secrets = {}

default_container_concurrency = 80

service_definitions = {
  "cloud-config" = {
    repository     = "cloud-config"
    container_port = 9296
    ingress = {
      external_enabled = false
    }
  }
  "service-discovery" = {
    repository     = "service-discovery"
    container_port = 8761
    ingress = {
      external_enabled = false
    }
  }
}

