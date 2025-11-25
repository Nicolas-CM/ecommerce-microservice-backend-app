# Script de despliegue de microservicios en AKS con Helm (PowerShell)
# Uso: .\deploy.ps1 [-Environment dev] [-Namespace ecommerce]

param(
    [string]$Environment = "dev",
    [string]$Namespace = "ecommerce"
)

$ErrorActionPreference = "Stop"

# Configuración
$ChartDir = ".\ecommerce-chart"
$ValuesFile = ".\image-tags.yaml"
$ReleaseName = "ecommerce-microservices"

# Colores
function Write-Step {
    param([string]$Message)
    Write-Host "==> " -NoNewline -ForegroundColor Blue
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -NoNewline -ForegroundColor Green
    Write-Host $Message
}

function Write-Err {
    param([string]$Message)
    Write-Host "✗ " -NoNewline -ForegroundColor Red
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "! " -NoNewline -ForegroundColor Yellow
    Write-Host $Message
}

function Check-Prerequisites {
    Write-Step "Verificando prerequisitos..."
    
    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Err "kubectl no está instalado"
        exit 1
    }
    Write-Success "kubectl encontrado"
    
    # Check helm
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        Write-Err "helm no está instalado"
        exit 1
    }
    Write-Success "helm encontrado"
    
    # Check AKS connection
    try {
        kubectl cluster-info | Out-Null
        Write-Success "Conectado al clúster de Kubernetes"
    }
    catch {
        Write-Err "No se puede conectar al clúster de Kubernetes"
        Write-Warn "Ejecuta: az aks get-credentials --resource-group <rg> --name <aks-name>"
        exit 1
    }
    
    # Check files
    if (-not (Test-Path $ChartDir)) {
        Write-Err "Chart directory no encontrado: $ChartDir"
        exit 1
    }
    Write-Success "Chart directory encontrado"
    
    if (-not (Test-Path $ValuesFile)) {
        Write-Err "Values file no encontrado: $ValuesFile"
        exit 1
    }
    Write-Success "Values file encontrado"
}

function Create-Namespace {
    Write-Step "Verificando namespace: $Namespace"
    
    $nsExists = kubectl get namespace $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Namespace $Namespace ya existe"
    }
    else {
        Write-Step "Creando namespace $Namespace..."
        kubectl create namespace $Namespace
        Write-Success "Namespace $Namespace creado"
    }
}

function Check-GHCRSecret {
    Write-Step "Verificando secreto de GHCR..."
    
    $secretExists = kubectl get secret ghcr-secret -n $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Secreto ghcr-secret encontrado"
    }
    else {
        Write-Warn "Secreto ghcr-secret NO encontrado"
        Write-Host ""
        Write-Host "Para crear el secreto, ejecuta:"
        Write-Host ""
        Write-Host "kubectl create secret docker-registry ghcr-secret ``"
        Write-Host "  --docker-server=ghcr.io ``"
        Write-Host "  --docker-username=Nicolas-CM ``"
        Write-Host "  --docker-password=<GITHUB_PAT> ``"
        Write-Host "  --docker-email=tu-email@ejemplo.com ``"
        Write-Host "  --namespace=$Namespace"
        Write-Host ""
        
        $continue = Read-Host "¿Deseas continuar de todas formas? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 1
        }
    }
}

function Test-Chart {
    Write-Step "Validando sintaxis del chart..."
    
    helm lint $ChartDir --values $ValuesFile
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Chart válido"
    }
    else {
        Write-Err "Chart tiene errores de sintaxis"
        exit 1
    }
}

function Invoke-DryRun {
    Write-Step "Ejecutando dry-run..."
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════"
    Write-Host "  DRY RUN - No se aplicarán cambios"
    Write-Host "═══════════════════════════════════════════════════════"
    Write-Host ""
    
    $output = helm upgrade --install $ReleaseName $ChartDir `
        --namespace $Namespace `
        --values $ValuesFile `
        --dry-run --debug 2>&1
    
    $output | Select-Object -First 50
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════"
    Write-Host ""
    
    Write-Success "Dry-run completado"
    Write-Host ""
    
    $continue = Read-Host "¿Deseas continuar con el despliegue real? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Warn "Despliegue cancelado por el usuario"
        exit 0
    }
}

function Deploy-Application {
    Write-Step "Desplegando microservicios..."
    
    Write-Host ""
    helm upgrade --install $ReleaseName $ChartDir `
        --namespace $Namespace `
        --create-namespace `
        --values $ValuesFile `
        --wait `
        --timeout 10m
    
    Write-Success "Despliegue completado"
}

function Show-Status {
    Write-Step "Estado del despliegue:"
    Write-Host ""
    
    # Helm release status
    Write-Host "═══ Helm Release ═══"
    helm status $ReleaseName -n $Namespace
    Write-Host ""
    
    # Pods
    Write-Host "═══ Pods ═══"
    kubectl get pods -n $Namespace
    Write-Host ""
    
    # Services
    Write-Host "═══ Services ═══"
    kubectl get svc -n $Namespace
    Write-Host ""
}

function Show-Endpoints {
    Write-Step "Endpoints de acceso:"
    Write-Host ""
    
    # API Gateway
    $apiGatewayType = kubectl get svc api-gateway -n $Namespace -o jsonpath='{.spec.type}' 2>$null
    
    if ($apiGatewayType -eq "LoadBalancer") {
        $apiGatewayIP = kubectl get svc api-gateway -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($apiGatewayIP) {
            Write-Host "API Gateway: http://${apiGatewayIP}:8080"
        }
        else {
            Write-Warn "API Gateway LoadBalancer IP aún no asignado"
            Write-Host "Ejecuta: kubectl get svc api-gateway -n $Namespace -w"
        }
    }
    else {
        Write-Warn "API Gateway no es tipo LoadBalancer"
        Write-Host "Para acceder localmente:"
        Write-Host "kubectl port-forward svc/api-gateway 8080:8080 -n $Namespace"
    }
    
    # Eureka
    Write-Host ""
    Write-Host "Eureka Dashboard:"
    Write-Host "kubectl port-forward svc/service-discovery 8761:8761 -n $Namespace"
    Write-Host "Luego visita: http://localhost:8761"
    
    # Zipkin
    Write-Host ""
    Write-Host "Zipkin Tracing:"
    Write-Host "kubectl port-forward svc/zipkin 9411:9411 -n $Namespace"
    Write-Host "Luego visita: http://localhost:9411"
    
    Write-Host ""
}

function Watch-Rollout {
    Write-Step "Monitoreando despliegue..."
    Write-Host ""
    
    $watch = Read-Host "¿Deseas ver el progreso de los pods? (y/N)"
    if ($watch -eq "y" -or $watch -eq "Y") {
        kubectl get pods -n $Namespace -w
    }
}

# Main
function Main {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════"
    Write-Host "  Despliegue de E-Commerce Microservices"
    Write-Host "  Environment: $Environment"
    Write-Host "  Namespace: $Namespace"
    Write-Host "═══════════════════════════════════════════════════════"
    Write-Host ""
    
    Check-Prerequisites
    Create-Namespace
    Check-GHCRSecret
    Test-Chart
    Invoke-DryRun
    Deploy-Application
    Show-Status
    Show-Endpoints
    
    Write-Host ""
    Write-Success "¡Despliegue completado exitosamente!"
    Write-Host ""
    
    Watch-Rollout
}

# Run
Main
