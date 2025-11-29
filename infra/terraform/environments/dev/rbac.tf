data "kubernetes_namespace" "ecommerce_dev" {
  metadata {
    name = "ecommerce-dev"
  }
}

resource "kubernetes_service_account" "dev_user" {
  metadata {
    name      = "dev-user"
    namespace = data.kubernetes_namespace.ecommerce_dev.metadata[0].name
  }
}

resource "kubernetes_role" "dev_reader" {
  metadata {
    name      = "dev-reader"
    namespace = data.kubernetes_namespace.ecommerce_dev.metadata[0].name
  }

  rule {
    api_groups = ["", "apps", "networking.k8s.io"]
    resources  = ["pods", "services", "configmaps", "secrets", "deployments", "ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "dev_user_binding" {
  metadata {
    name      = "dev-user-binding"
    namespace = data.kubernetes_namespace.ecommerce_dev.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.dev_reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.dev_user.metadata[0].name
    namespace = data.kubernetes_namespace.ecommerce_dev.metadata[0].name
  }
}
