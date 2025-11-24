# Comandos para reconstruir y probar imágenes optimizadas

Sigue estos pasos para reconstruir y probar tus servicios con los Dockerfile optimizados:

---

## 1. Construye las imágenes de todos los servicios

```sh
# Desde la raíz del proyecto
cd user-service && docker build -t user-service:latest . && cd ..
cd order-service && docker build -t order-service:latest . && cd ..
cd payment-service && docker build -t payment-service:latest . && cd ..
cd product-service && docker build -t product-service:latest . && cd ..
cd shipping-service && docker build -t shipping-service:latest . && cd ..
cd favourite-service && docker build -t favourite-service:latest . && cd ..
cd cloud-config && docker build -t cloud-config:latest . && cd ..
cd service-discovery && docker build -t service-discovery:latest . && cd ..
cd api-gateway && docker build -t api-gateway:latest . && cd ..
cd proxy-client && docker build -t proxy-client:latest . && cd ..
```

---

## 2. Sube las imágenes a Minikube

Si usas Minikube, ejecuta antes:

```sh
minikube docker-env
# Sigue las instrucciones que te da el comando para exportar las variables de entorno
```

Luego repite el paso de build para que las imágenes estén disponibles en el clúster de Minikube.

---

## 3. Despliega tus servicios

Usa tus manifiestos YAML de Kubernetes (`kubectl apply -f k8s/base/`) o el método que prefieras.

---

## 4. Verifica que los pods estén corriendo

```sh
kubectl get pods -A
```

---

Con esto, tus servicios estarán usando las imágenes optimizadas y listas para producción en Minikube.
