subscription_id  = "e1a90c9e-5db0-43f3-9c1f-81fcea17e6bc"
tenant_id        = "e994072b-523e-4bfe-86e2-442c5e10b244"
location         = "mexicocentral"
global_prefix    = "eco"
environment_name = "dev"

network_address_space        = ["10.20.0.0/16"]
log_analytics_retention_days = 30

# AKS Configuration
kubernetes_version      = "1.31.2"
aks_node_count          = 2
aks_vm_size             = "Standard_B4s_v2"
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
