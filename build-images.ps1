# Script para construir todas las imagenes Docker en Minikube
Write-Host "Construyendo imagenes Docker para Minikube..." -ForegroundColor Cyan

# Configurar Docker para usar el daemon de Minikube
Write-Host "Configurando Docker para Minikube..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Lista de servicios
$services = @(
    "service-discovery",
    "cloud-config",
    "api-gateway",
    "proxy-client",
    "user-service",
    "product-service",
    "order-service",
    "payment-service",
    "shipping-service",
    "favourite-service"
)

$version = "0.1.0"

foreach ($service in $services) {
    Write-Host "Construyendo $service..." -ForegroundColor Green
    
    Set-Location $service
    
    # Construir imagen
    docker build -t "${service}:${version}" -t "${service}:latest" .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $service construido exitosamente" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Error construyendo $service" -ForegroundColor Red
    }
    
    Set-Location ..
}

Write-Host ""
Write-Host "Listando imagenes construidas:" -ForegroundColor Cyan
docker images | Select-String -Pattern "service|gateway|proxy|cloud"

Write-Host ""
Write-Host "Todas las imagenes construidas exitosamente!" -ForegroundColor Green
