# Script para actualizar proxy-client en Minikube
Write-Host "1. Configurando entorno Docker de Minikube..."
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

Write-Host "2. Compilando proxy-client..."
.\mvnw.cmd clean package -DskipTests -pl proxy-client -am

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en la compilación Maven" -ForegroundColor Red
    exit 1
}

Write-Host "3. Construyendo imagen Docker (proxy-client:latest)..."
docker build -t proxy-client:latest proxy-client

Write-Host "4. Reiniciando Deployment en Kubernetes..."
kubectl rollout restart deployment proxy-client -n ecommerce

Write-Host "5. Esperando a que el pod esté listo..."
kubectl rollout status deployment/proxy-client -n ecommerce

Write-Host "¡Actualización completada! Ahora puedes correr el test." -ForegroundColor Green
