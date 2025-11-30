output "namespace" {
  description = "Namespace donde está instalado el stack de monitoreo"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_service_name" {
  description = "Nombre del servicio de Prometheus"
  value       = "kube-prometheus-stack-prometheus"
}

output "grafana_service_name" {
  description = "Nombre del servicio de Grafana"
  value       = "kube-prometheus-stack-grafana"
}

output "elasticsearch_service_name" {
  description = "Nombre del servicio de Elasticsearch"
  value       = "elasticsearch-master"
}

output "kibana_service_name" {
  description = "Nombre del servicio de Kibana"
  value       = "kibana-kibana"
}

output "logstash_service_name" {
  description = "Nombre del servicio de Logstash"
  value       = "logstash-logstash"
}

output "port_forward_commands" {
  description = "Comandos para acceder a los servicios de monitoreo"
  value = {
    grafana       = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/kube-prometheus-stack-grafana 3000:80"
    prometheus    = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/kube-prometheus-stack-prometheus 9090:9090"
    kibana        = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/kibana-kibana 5601:5601"
    elasticsearch = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/elasticsearch-master 9200:9200"
  }
}
