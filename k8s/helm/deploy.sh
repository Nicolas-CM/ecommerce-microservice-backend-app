#!/bin/bash

# Script de despliegue de microservicios en AKS con Helm
# Uso: ./deploy.sh [ENVIRONMENT] [NAMESPACE]

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
ENVIRONMENT=${1:-dev}
NAMESPACE=${2:-ecommerce}
CHART_DIR="./ecommerce-chart"
VALUES_FILE="./image-tags.yaml"
RELEASE_NAME="ecommerce-microservices"

# Funciones
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

check_prerequisites() {
    print_step "Verificando prerequisitos..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    print_success "kubectl encontrado"
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm no está instalado"
        exit 1
    fi
    print_success "helm encontrado"
    
    # Check AKS connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "No se puede conectar al clúster de Kubernetes"
        print_warning "Ejecuta: az aks get-credentials --resource-group <rg> --name <aks-name>"
        exit 1
    fi
    print_success "Conectado al clúster de Kubernetes"
    
    # Check files
    if [ ! -d "$CHART_DIR" ]; then
        print_error "Chart directory no encontrado: $CHART_DIR"
        exit 1
    fi
    print_success "Chart directory encontrado"
    
    if [ ! -f "$VALUES_FILE" ]; then
        print_error "Values file no encontrado: $VALUES_FILE"
        exit 1
    fi
    print_success "Values file encontrado"
}

create_namespace() {
    print_step "Verificando namespace: $NAMESPACE"
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_success "Namespace $NAMESPACE ya existe"
    else
        print_step "Creando namespace $NAMESPACE..."
        kubectl create namespace $NAMESPACE
        print_success "Namespace $NAMESPACE creado"
    fi
}

check_ghcr_secret() {
    print_step "Verificando secreto de GHCR..."
    
    if kubectl get secret ghcr-secret -n $NAMESPACE &> /dev/null; then
        print_success "Secreto ghcr-secret encontrado"
    else
        print_warning "Secreto ghcr-secret NO encontrado"
        echo ""
        echo "Para crear el secreto, ejecuta:"
        echo ""
        echo "kubectl create secret docker-registry ghcr-secret \\"
        echo "  --docker-server=ghcr.io \\"
        echo "  --docker-username=Nicolas-CM \\"
        echo "  --docker-password=<GITHUB_PAT> \\"
        echo "  --docker-email=tu-email@ejemplo.com \\"
        echo "  --namespace=$NAMESPACE"
        echo ""
        read -p "¿Deseas continuar de todas formas? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

lint_chart() {
    print_step "Validando sintaxis del chart..."
    
    if helm lint $CHART_DIR --values $VALUES_FILE; then
        print_success "Chart válido"
    else
        print_error "Chart tiene errores de sintaxis"
        exit 1
    fi
}

dry_run() {
    print_step "Ejecutando dry-run..."
    
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  DRY RUN - No se aplicarán cambios"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    helm upgrade --install $RELEASE_NAME $CHART_DIR \
        --namespace $NAMESPACE \
        --values $VALUES_FILE \
        --dry-run --debug \
        2>&1 | head -n 50
    
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    print_success "Dry-run completado"
    echo ""
    read -p "¿Deseas continuar con el despliegue real? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Despliegue cancelado por el usuario"
        exit 0
    fi
}

deploy() {
    print_step "Desplegando microservicios..."
    
    echo ""
    helm upgrade --install $RELEASE_NAME $CHART_DIR \
        --namespace $NAMESPACE \
        --create-namespace \
        --values $VALUES_FILE \
        --wait \
        --timeout 10m
    
    print_success "Despliegue completado"
}

show_status() {
    print_step "Estado del despliegue:"
    echo ""
    
    # Helm release status
    echo "═══ Helm Release ═══"
    helm status $RELEASE_NAME -n $NAMESPACE
    echo ""
    
    # Pods
    echo "═══ Pods ═══"
    kubectl get pods -n $NAMESPACE
    echo ""
    
    # Services
    echo "═══ Services ═══"
    kubectl get svc -n $NAMESPACE
    echo ""
}

show_endpoints() {
    print_step "Endpoints de acceso:"
    echo ""
    
    # API Gateway
    API_GATEWAY_TYPE=$(kubectl get svc api-gateway -n $NAMESPACE -o jsonpath='{.spec.type}')
    
    if [ "$API_GATEWAY_TYPE" = "LoadBalancer" ]; then
        API_GATEWAY_IP=$(kubectl get svc api-gateway -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ -n "$API_GATEWAY_IP" ]; then
            echo "API Gateway: http://$API_GATEWAY_IP:8080"
        else
            print_warning "API Gateway LoadBalancer IP aún no asignado"
            echo "Ejecuta: kubectl get svc api-gateway -n $NAMESPACE -w"
        fi
    else
        print_warning "API Gateway no es tipo LoadBalancer"
        echo "Para acceder localmente:"
        echo "kubectl port-forward svc/api-gateway 8080:8080 -n $NAMESPACE"
    fi
    
    # Eureka (Service Discovery)
    echo ""
    echo "Eureka Dashboard:"
    echo "kubectl port-forward svc/service-discovery 8761:8761 -n $NAMESPACE"
    echo "Luego visita: http://localhost:8761"
    
    # Zipkin
    echo ""
    echo "Zipkin Tracing:"
    echo "kubectl port-forward svc/zipkin 9411:9411 -n $NAMESPACE"
    echo "Luego visita: http://localhost:9411"
    
    echo ""
}

watch_rollout() {
    print_step "Monitoreando despliegue..."
    echo ""
    
    read -p "¿Deseas ver el progreso de los pods? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl get pods -n $NAMESPACE -w
    fi
}

# Main
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Despliegue de E-Commerce Microservices"
    echo "  Environment: $ENVIRONMENT"
    echo "  Namespace: $NAMESPACE"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    check_prerequisites
    create_namespace
    check_ghcr_secret
    lint_chart
    dry_run
    deploy
    show_status
    show_endpoints
    
    echo ""
    print_success "¡Despliegue completado exitosamente!"
    echo ""
    
    watch_rollout
}

# Run
main
