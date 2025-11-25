output "network_id" {
  description = "Self link of the created VPC network."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "Name of the created VPC network."
  value       = google_compute_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet identifiers to their self links."
  value = {
    for key, subnet in google_compute_subnetwork.this :
    key => subnet.self_link
  }
}
