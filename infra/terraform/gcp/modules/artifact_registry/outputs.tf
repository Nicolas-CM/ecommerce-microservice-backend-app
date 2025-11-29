locals {
  repository_endpoint = format(
    "%s-docker.pkg.dev/%s/%s",
    var.location,
    var.project_id,
    var.repository_id
  )
}

output "repository_id" {
  description = "ID of the Artifact Registry repository."
  value       = google_artifact_registry_repository.this.repository_id
}

output "repository_endpoint" {
  description = "URL prefix to push/pull container images."
  value       = local.repository_endpoint
}

output "repository_resource" {
  description = "Full resource name of the repository."
  value       = google_artifact_registry_repository.this.name
}
