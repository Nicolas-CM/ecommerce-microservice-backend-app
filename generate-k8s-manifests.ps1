# Script para generar manifiestos K8s para todos los microservicios
Write-Host "Generando manifiestos de Kubernetes..." -ForegroundColor Cyan

$services = @(
    @{Name="product-service"; Port=8500},
    @{Name="order-service"; Port=8300},
    @{Name="payment-service"; Port=8400},
    @{Name="shipping-service"; Port=8600},
    @{Name="favourite-service"; Port=8800},
    @{Name="api-gateway"; Port=8080},
    @{Name="proxy-client"; Port=8900}
)

foreach ($service in $services) {
    $serviceName = $service.Name
    $port = $service.Port
    
    Write-Host "Generando $serviceName..." -ForegroundColor Green
    
    $manifest = @"
---
# $serviceName Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $serviceName
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $serviceName
  template:
    metadata:
      labels:
        app: $serviceName
    spec:
      containers:
      - name: $serviceName
        image: selimhorri/${serviceName}-ecommerce-boot:0.1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: $port
          name: http
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
          valueFrom:
            configMapKeyRef:
              name: eureka-config
              key: EUREKA_SERVER_URL
        - name: SPRING_ZIPKIN_BASE_URL
          valueFrom:
            configMapKeyRef:
              name: zipkin-config
              key: ZIPKIN_BASE_URL
        - name: SPRING_CONFIG_IMPORT
          value: "optional:configserver:http://cloud-config:9296/"
        - name: EUREKA_INSTANCE_PREFER_IP_ADDRESS
          value: "false"
        - name: EUREKA_INSTANCE_HOSTNAME
          value: "$serviceName"
        - name: EUREKA_CLIENT_ENABLED
          value: "true"
        - name: EUREKA_CLIENT_FETCH_REGISTRY
          value: "true"
        - name: RIBBON_EUREKA_ENABLED
          value: "true"
---
# $serviceName Service
apiVersion: v1
kind: Service
metadata:
  name: $serviceName
  namespace: ecommerce
spec:
  type: ClusterIP
  ports:
  - port: $port
    targetPort: $port
    protocol: TCP
    name: http
  selector:
    app: $serviceName
"@

    $manifest | Out-File -FilePath "k8s/base/$serviceName.yaml" -Encoding UTF8
}

Write-Host "Todos los manifiestos generados en k8s/base/" -ForegroundColor Green
