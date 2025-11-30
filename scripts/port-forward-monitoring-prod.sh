#!/bin/bash

# Script para acceder al stack de monitoreo en Producción

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="monitoring"
AKS_CLUSTER_NAME="eco-prod-aks"
RESOURCE_GROUP="eco-prod-rg"

echo -e "${BLUE}🚀 Configurando acceso al Stack de Monitoreo (Producción)${NC}"
echo ""

# Verificar si az cli está instalado
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI no está instalado${NC}"
    echo -e "${YELLOW}Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli${NC}"
    exit 1
fi

# Verificar si kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl no está instalado${NC}"
    exit 1
fi

echo -e "${YELLOW}Conectando al cluster AKS...${NC}"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

# Verificar conexión al cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗ No se puede conectar al cluster de Kubernetes${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Conectado al cluster de Kubernetes${NC}"
echo ""

# Verificar que el namespace existe
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${RED}✗ El namespace $NAMESPACE no existe${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Namespace $NAMESPACE encontrado${NC}"
echo ""

# Función para iniciar port-forward
start_port_forward() {
    local service=$1
    local local_port=$2
    local remote_port=$3
    local name=$4

    echo -e "${BLUE}Iniciando port-forward para $name...${NC}"
    kubectl port-forward -n $NAMESPACE svc/$service $local_port:$remote_port > /dev/null 2>&1 &
    PID=$!
    echo $PID >> /tmp/monitoring-pids-prod.txt
    sleep 2

    if ps -p $PID > /dev/null; then
        echo -e "${GREEN}✓ $name disponible en http://localhost:$local_port${NC}"
    else
        echo -e "${RED}✗ Error al iniciar port-forward para $name${NC}"
    fi
}

# Limpiar port-forwards anteriores
if [ -f /tmp/monitoring-pids-prod.txt ]; then
    echo -e "${YELLOW}Limpiando port-forwards anteriores...${NC}"
    while read pid; do
        kill $pid 2>/dev/null
    done < /tmp/monitoring-pids-prod.txt
    rm /tmp/monitoring-pids-prod.txt
fi

echo -e "${YELLOW}Iniciando port-forwards...${NC}"
echo ""

# Grafana
start_port_forward "kube-prometheus-stack-grafana" 3000 80 "Grafana"

# Prometheus
start_port_forward "kube-prometheus-stack-prometheus" 9090 9090 "Prometheus"

# Kibana
start_port_forward "kibana-kibana" 5601 5601 "Kibana"

# Elasticsearch
start_port_forward "elasticsearch-master" 9200 9200 "Elasticsearch"

echo ""
echo -e "${GREEN}=== Stack de Monitoreo Activo (Producción) ===${NC}"
echo ""
echo -e "📊 ${BLUE}Grafana:${NC}       http://localhost:3000"
echo -e "   ${YELLOW}Usuario:${NC} admin"
echo -e "   ${YELLOW}Password:${NC} (usa el secret de GitHub: GRAFANA_ADMIN_PASSWORD)"
echo ""
echo -e "🔥 ${BLUE}Prometheus:${NC}    http://localhost:9090"
echo -e "🪵 ${BLUE}Kibana:${NC}        http://localhost:5601"
echo -e "🔍 ${BLUE}Elasticsearch:${NC} http://localhost:9200"
echo ""
echo -e "${YELLOW}Para detener todos los port-forwards:${NC}"
echo -e "kill \$(cat /tmp/monitoring-pids-prod.txt)"
echo ""
echo -e "${GREEN}Presiona Ctrl+C para salir${NC}"

# Mantener el script corriendo
wait
