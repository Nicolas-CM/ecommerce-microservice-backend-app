output "name" {
  description = "Name of the Cloud Run service."
  value       = google_cloud_run_service.this.name
}

output "url" {
  description = "Public URL of the service."
  value       = google_cloud_run_service.this.status[0].url
}
