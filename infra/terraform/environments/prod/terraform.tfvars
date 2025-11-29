subscription_id  = "e1a90c9e-5db0-43f3-9c1f-81fcea17e6bc"
tenant_id        = "e994072b-523e-4bfe-86e2-442c5e10b244"
location         = "centralus"
global_prefix    = "eco"
environment_name = "prod"

network_address_space        = ["10.30.0.0/16"]
log_analytics_retention_days = 60

# AKS Configuration
kubernetes_version      = "1.31.2"
aks_node_count          = 2
aks_vm_size             = "Standard_B4s_v2"
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
