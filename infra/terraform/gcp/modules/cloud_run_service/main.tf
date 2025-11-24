locals {
  template_annotations = merge(
    {
      "autoscaling.knative.dev/minScale" = tostring(var.min_instances)
      "autoscaling.knative.dev/maxScale" = tostring(var.max_instances)
    },
    var.additional_annotations
  )
}

resource "google_cloud_run_service" "this" {
  name     = var.name
  project  = var.project_id
  location = var.region

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = var.ingress_type
    }
    labels = var.labels
  }

  template {
    metadata {
      annotations = local.template_annotations
      labels      = var.labels
    }

    spec {
      service_account_name  = var.service_account_email
      container_concurrency = var.container_concurrency

      containers {
        image = var.image

        ports {
          name           = "http1"
          container_port = var.container_port
        }

        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }

        dynamic "env" {
          for_each = var.env
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = var.secrets
          iterator = secret
          content {
            name = secret.key
            value_from {
              secret_key_ref {
                secret  = secret.value.secret
                version = secret.value.version
              }
            }
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "public" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = google_cloud_run_service.this.location
  project  = google_cloud_run_service.this.project
  service  = google_cloud_run_service.this.name

  role   = "roles/run.invoker"
  member = "allUsers"
}
