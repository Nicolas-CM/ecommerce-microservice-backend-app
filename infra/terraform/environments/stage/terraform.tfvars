subscription_id  = "079ab1f2-9528-44da-ba22-d60a88fdb0b8"
tenant_id        = "e994072b-523e-4bfe-86e2-442c5e10b244"
location         = "mexicocentral"
global_prefix    = "eco"
environment_name = "stage"

network_address_space        = ["10.30.0.0/16"]
log_analytics_retention_days = 60

# AKS Configuration
kubernetes_version      = "1.31.2"
aks_node_count          = 2
aks_vm_size             = "Standard_B4ms"
aks_enable_auto_scaling = true
aks_min_count           = 1
aks_max_count           = 5
aks_subnet_cidr         = "10.30.2.0/24"
aks_service_cidr        = "10.1.0.0/16"
aks_dns_service_ip      = "10.1.0.10"

tags = {
  Project = "ecommerce-microservices"
  Owner   = "platform-team"
}
