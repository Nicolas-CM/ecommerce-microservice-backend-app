locals {
  name_prefix = format("%s-%s", var.global_prefix, var.environment_name)

  labels = merge(
    var.labels,
    {
      environment = var.environment_name
    }
  )

  artifact_registry_location = coalesce(var.artifact_registry_location, var.region)
  artifact_repository_id     = coalesce(var.artifact_registry_repository_id, replace(format("%s-services", local.name_prefix), "_", "-"))

  normalized_services = {
    for service_name, service in var.service_definitions :
    service_name => {
      image = coalesce(
        try(service.image, null),
        format(
          "%s/%s:%s",
          module.artifact_registry.repository_endpoint,
          coalesce(try(service.repository, null), service_name),
          var.image_tag
        )
      )
      container_port = try(service.container_port, 8080)
      cpu            = tostring(try(service.cpu, 1))
      memory = coalesce(
        try(service.memory, null),
        format(
          "%dMi",
          ceil(coalesce(try(service.memory_gb, null), 1) * 1024)
        )
      )
      env                   = try(service.env, {})
      secrets               = try(service.secrets, {})
      min_instances         = try(service.min_replicas, 0)
      max_instances         = try(service.max_replicas, 5)
      container_concurrency = try(service.container_concurrency, var.default_container_concurrency)
      allow_unauthenticated = coalesce(
        try(service.ingress.allow_unauthenticated, null),
        try(service.ingress.external_enabled, null),
        true
      )
      ingress_type = try(service.ingress.external_enabled, true) ? "all" : "internal"
    }
  }
}

module "network" {
  source       = "../../modules/network"
  project_id   = var.project_id
  name         = format("%s-vpc", local.name_prefix)
  description  = "VPC network for ${local.name_prefix}"
  routing_mode = var.vpc_routing_mode

  subnets = {
    primary = {
      name          = format("%s-subnet", local.name_prefix)
      region        = var.region
      ip_cidr_range = var.subnet_cidr_block
    }
  }
}

module "artifact_registry" {
  source        = "../../modules/artifact_registry"
  project_id    = var.project_id
  location      = local.artifact_registry_location
  repository_id = local.artifact_repository_id
  labels        = local.labels
}

module "cloud_run_service" {
  for_each = local.normalized_services
  source   = "../../modules/cloud_run_service"

  project_id = var.project_id
  region     = var.region
  name       = format("%s-%s", local.name_prefix, each.key)
  image      = each.value.image

  container_port        = each.value.container_port
  cpu                   = each.value.cpu
  memory                = each.value.memory
  container_concurrency = each.value.container_concurrency
  min_instances         = each.value.min_instances
  max_instances         = each.value.max_instances
  ingress_type          = each.value.ingress_type
  allow_unauthenticated = each.value.allow_unauthenticated

  env     = merge(var.default_environment_variables, each.value.env)
  secrets = merge(var.default_secrets, each.value.secrets)
  labels  = local.labels
}
