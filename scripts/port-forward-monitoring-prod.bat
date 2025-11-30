@echo off
REM Script para acceder al stack de monitoreo en Producción (Windows)

setlocal enabledelayedexpansion

set NAMESPACE=monitoring
set AKS_CLUSTER_NAME=eco-prod-aks
set RESOURCE_GROUP=eco-prod-rg

echo.
echo ===================================================
echo   Configurando acceso al Stack de Monitoreo
echo   Entorno: PRODUCCION
echo ===================================================
echo.

REM Verificar Azure CLI
where az >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Azure CLI no esta instalado
    echo Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli
    exit /b 1
)

REM Verificar kubectl
where kubectl >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] kubectl no esta instalado
    exit /b 1
)

echo [INFO] Conectando al cluster AKS...
az aks get-credentials --resource-group %RESOURCE_GROUP% --name %AKS_CLUSTER_NAME% --overwrite-existing

REM Verificar conexión
kubectl cluster-info >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] No se puede conectar al cluster de Kubernetes
    exit /b 1
)

echo [OK] Conectado al cluster de Kubernetes
echo.

REM Verificar namespace
kubectl get namespace %NAMESPACE% >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] El namespace %NAMESPACE% no existe
    exit /b 1
)

echo [OK] Namespace %NAMESPACE% encontrado
echo.

echo ===================================================
echo   Iniciando Port-Forwards
echo ===================================================
echo.

REM Limpiar procesos anteriores
if exist monitoring-pids-prod.txt (
    echo [INFO] Limpiando port-forwards anteriores...
    for /f %%i in (monitoring-pids-prod.txt) do taskkill /PID %%i /F >nul 2>nul
    del monitoring-pids-prod.txt
)

REM Grafana
echo [INFO] Iniciando port-forward para Grafana...
start /B kubectl port-forward -n %NAMESPACE% svc/kube-prometheus-stack-grafana 3000:80
timeout /t 2 /nobreak >nul
echo [OK] Grafana disponible en http://localhost:3000

REM Prometheus
echo [INFO] Iniciando port-forward para Prometheus...
start /B kubectl port-forward -n %NAMESPACE% svc/kube-prometheus-stack-prometheus 9090:9090
timeout /t 2 /nobreak >nul
echo [OK] Prometheus disponible en http://localhost:9090

REM Kibana
echo [INFO] Iniciando port-forward para Kibana...
start /B kubectl port-forward -n %NAMESPACE% svc/kibana-kibana 5601:5601
timeout /t 2 /nobreak >nul
echo [OK] Kibana disponible en http://localhost:5601

REM Elasticsearch
echo [INFO] Iniciando port-forward para Elasticsearch...
start /B kubectl port-forward -n %NAMESPACE% svc/elasticsearch-master 9200:9200
timeout /t 2 /nobreak >nul
echo [OK] Elasticsearch disponible en http://localhost:9200

echo.
echo ===================================================
echo   Stack de Monitoreo Activo (PRODUCCION)
echo ===================================================
echo.
echo   Grafana:       http://localhost:3000
echo   Usuario:       admin
echo   Password:      (usa el secret: GRAFANA_ADMIN_PASSWORD)
echo.
echo   Prometheus:    http://localhost:9090
echo   Kibana:        http://localhost:5601
echo   Elasticsearch: http://localhost:9200
echo.
echo ===================================================
echo.
echo [INFO] Presiona Ctrl+C para salir
echo.

REM Mantener la ventana abierta
pause
