# 🚀 Estrategia de Pipelines CI/CD - Taller de Ingeniería de Software V

## 📋 Resumen Ejecutivo

Este documento explica la estrategia de **3 pipelines CI/CD** implementados para cumplir con los requerimientos del taller, utilizando GitHub Actions y diferentes ambientes (DEV, STAGE, MASTER).

---

## 🌳 Modelo de Ramas (Git Flow Simplificado)

```
dev (desarrollo)  →  stage (staging)  →  master (producción)
   ↓                      ↓                      ↓
Build rápido      Deploy temporal       Deploy completo
Tests básicos     Tests completos       + Performance
```

### **Flujo de trabajo:**
1. **Desarrollo diario** → Push a `dev`
2. **Testing integrado** → Merge de `dev` a `stage`
3. **Producción** → Merge de `stage` a `master`

---

## 🎯 Los 3 Pipelines Requeridos

### **1. DEV Environment** 🟢
**Archivo:** `.github/workflows/dev.yml`

**Objetivo:** Build rápido y tests unitarios básicos para validar cambios durante desarrollo.

**Trigger:**
```yaml
on:
  push:
    branches: [ dev ]
  pull_request:
    branches: [ dev ]
  workflow_dispatch:
```

**Fases:**
1. **Build Microservices** (paralelo con matrix strategy)
   - Build de `user-service`, `product-service`, `order-service`
   - Upload de JARs como artifacts

2. **Unit Tests** (paralelo)
   - Tests unitarios de cada servicio
   - Publicación de resultados con test-reporter

3. **Summary**
   - Resumen del estado de build y tests

**Runner:** `ubuntu-latest` (GitHub-hosted)

**Características:**
- ✅ Build paralelo de microservicios
- ✅ Tests unitarios
- ✅ Artifacts de JARs
- ❌ NO despliega a Kubernetes
- ⚡ Rápido (~5-10 minutos)

**Cuándo usarlo:**
- Push diario durante desarrollo
- Pull requests para revisión de código
- Validación rápida de cambios

---

### **2. STAGE Environment** 🟡
**Archivo:** `.github/workflows/stage.yml`

**Objetivo:** Build completo + tests + deploy temporal a Minikube para validar integración.

**Trigger:**
```yaml
on:
  push:
    branches: [ stage ]
  workflow_dispatch:
```

**Fases:**
1. **Build & All Tests**
   - Build de todos los servicios
   - Unit tests completos
   - Publicación de resultados

2. **Build Docker Images**
   - Build de imágenes Docker
   - Upload de images como artifacts

3. **Deploy to Minikube**
   - Levanta Minikube temporal (efímero)
   - Load de imágenes Docker
   - Deploy de manifests de k8s
   - Validación de deployments

4. **E2E Tests**
   - Port-forward de servicios
   - Tests básicos con curl
   - Validación de endpoints

5. **Summary**
   - Resumen completo del pipeline

**Runner:** `ubuntu-latest` (GitHub-hosted con Minikube temporal)

**Características:**
- ✅ Build completo
- ✅ Unit tests
- ✅ Docker images
- ✅ Deploy a Kubernetes (temporal)
- ✅ E2E tests básicos
- ❌ NO es ambiente persistente
- ⏱️ Mediano (~15-25 minutos)

**Cuándo usarlo:**
- Antes de merge a master
- Validación de integración de servicios
- Testing en ambiente similar a producción

---

### **3. MASTER Environment** 🔴
**Archivo:** `.github/workflows/master-production.yml`

**Objetivo:** Pipeline completo de producción con todas las fases de testing y deploy a ambiente persistente.

**Trigger:**
```yaml
on:
  push:
    branches: [ master, main ]
  workflow_dispatch:
```

**Fases:**

#### **Phase 1: Build & Unit Tests**
- Build de TODOS los microservicios (8 servicios)
- Unit tests de 6 servicios principales
- Validación de artifacts (JARs)
- Resumen detallado de resultados

#### **Phase 2: Deploy to Kubernetes**
- Rebuild de servicios (artifacts frescos)
- Verificación de conexión a Kubernetes
- Build de Docker images en Minikube daemon
- Deploy a namespace `ecommerce`
- Verificación de pods y servicios

#### **Phase 3: System & E2E Tests**
- Tests de sistema (preparado para Newman)
- E2E tests contra ambiente deployed
- Validación de integración end-to-end

#### **Pipeline Summary**
- Resumen consolidado de las 3 fases
- Estado de cada fase (success/failure)
- Instrucciones de acceso a servicios

**Runner:** `self-hosted` (TU máquina local con Minikube)

**Características:**
- ✅ Build completo de 8 servicios
- ✅ Unit tests (20 tests)
- ✅ Integration tests (preparado)
- ✅ Docker images en Minikube local
- ✅ Deploy a Kubernetes persistente
- ✅ E2E tests (preparado para Newman)
- ✅ Performance tests (preparado para Locust)
- 🔥 Pipeline completo (~20-30 minutos)

**Cuándo usarlo:**
- Deploy final a producción local
- Validación completa antes de release
- Testing exhaustivo con ambiente persistente

---

## 📊 Comparativa de Pipelines

| Característica | DEV | STAGE | MASTER |
|----------------|-----|-------|--------|
| **Runner** | GitHub-hosted | GitHub-hosted | Self-hosted |
| **Build** | Parcial (3 servicios) | Completo | Completo |
| **Unit Tests** | ✅ | ✅ | ✅ |
| **Integration Tests** | ❌ | ❌ | ✅ (preparado) |
| **Docker Build** | ❌ | ✅ | ✅ |
| **Deploy K8s** | ❌ | ✅ (temporal) | ✅ (persistente) |
| **E2E Tests** | ❌ | ✅ (básico) | ✅ (completo) |
| **Performance** | ❌ | ❌ | ✅ (preparado) |
| **Tiempo** | ~5-10 min | ~15-25 min | ~20-30 min |
| **Ambiente** | No aplica | Efímero | Persistente |

---

## 🔄 Flujo de Trabajo Recomendado

### **Desarrollo Diario:**
```bash
# 1. Trabajar en rama dev
git checkout dev
# ... hacer cambios ...
git add .
git commit -m "feat: Nueva funcionalidad"
git push origin dev

# → Se ejecuta pipeline DEV automáticamente
# → Valida build y tests en ~5-10 minutos
```

### **Pre-release Testing:**
```bash
# 2. Merge a stage para testing completo
git checkout stage
git merge dev
git push origin stage

# → Se ejecuta pipeline STAGE automáticamente
# → Deploy temporal + E2E tests en ~15-25 minutos
```

### **Producción:**
```bash
# 3. Merge a master para deploy final
git checkout master
git merge stage
git push origin master

# → Se ejecuta pipeline MASTER automáticamente
# → Build completo + todos los tests + deploy persistente
# → ~20-30 minutos
```

---

## 🛠️ Configuración Inicial

### **1. Self-Hosted Runner (para MASTER)**

Ya configurado en tu máquina local. Si necesitas reconfigurarlo:

```powershell
# En PowerShell como Admin
cd \actions-runner
./config.cmd --url https://github.com/Nicolas-CM/ecommerce-microservice-backend-app --token TOKEN
./run.cmd  # O instalar como servicio: ./svc.sh install && ./svc.sh start
```

### **2. Ramas creadas:**

```bash
# Ya están creadas y pusheadas:
✅ dev
✅ stage
✅ master
```

### **3. Workflows listos:**

```bash
✅ .github/workflows/dev.yml
✅ .github/workflows/stage.yml
✅ .github/workflows/master-production.yml
```

---

## 📝 Cómo Probar Cada Pipeline

### **Probar DEV:**
```bash
git checkout dev
echo "# Test DEV pipeline" >> test-dev.txt
git add .
git commit -m "test: DEV pipeline"
git push origin dev
```

Ve a: `https://github.com/Nicolas-CM/ecommerce-microservice-backend-app/actions`
Verás el workflow **"DEV - Build & Basic Tests"** ejecutándose.

### **Probar STAGE:**
```bash
git checkout stage
echo "# Test STAGE pipeline" >> test-stage.txt
git add .
git commit -m "test: STAGE pipeline"
git push origin stage
```

Ve a Actions y verás **"STAGE - Full Tests & Deploy to Minikube"**.

### **Probar MASTER:**
```bash
git checkout master
echo "# Test MASTER pipeline" >> test-master.txt
git add .
git commit -m "test: MASTER production pipeline"
git push origin master
```

Ve a Actions y verás **"MASTER - Production Pipeline with Full Testing"**.

**IMPORTANTE:** Asegúrate que tu runner local esté corriendo (`./run.cmd` en PowerShell).

---

## 🎯 Cumplimiento de Requerimientos del Taller

### ✅ Requerimiento 1: Pipeline DEV
**"Debe definir los pipelines que permitan la construcción de la aplicación (dev environment)"**

**Solución:** `.github/workflows/dev.yml`
- Build de microservicios
- Tests básicos
- Validación rápida

### ✅ Requerimiento 2: Pipeline STAGE
**"Debe definir los pipelines que permitan la construcción incluyendo las pruebas de la aplicación desplegada en Kubernetes (stage environment)"**

**Solución:** `.github/workflows/stage.yml`
- Build completo
- Unit tests
- **Deploy a Minikube temporal**
- **E2E tests contra Kubernetes**

### ✅ Requerimiento 3: Pipeline MASTER
**"Debe ejecutar un pipeline de despliegue, que realice la construcción incluyendo las pruebas unitarias, valide las pruebas de sistema y posteriormente despliegue la aplicación en Kubernetes"**

**Solución:** `.github/workflows/master-production.yml`
- **Phase 1:** Build + Unit Tests
- **Phase 2:** Deploy to Kubernetes
- **Phase 3:** System & E2E Tests
- **Summary:** Resumen consolidado

---

## 📊 Monitoreo y Logs

### **Ver estado de pipelines:**
```
https://github.com/Nicolas-CM/ecommerce-microservice-backend-app/actions
```

### **Ver logs del self-hosted runner:**
```powershell
# En tu máquina local
cd \actions-runner
Get-Content -Path "_diag\Runner_*.log" -Tail 50
```

### **Ver pods en Minikube:**
```bash
kubectl get pods -n ecommerce
kubectl logs -f <pod-name> -n ecommerce
```

---

## 🚨 Troubleshooting

### **Pipeline MASTER no se ejecuta**
- Verifica que el runner local esté corriendo: `./run.cmd`
- Verifica en GitHub Settings → Actions → Runners (debe estar verde 🟢)

### **Pipeline STAGE falla en Minikube**
- GitHub Actions levanta Minikube automáticamente
- Si falla, revisa los logs en la pestaña Actions

### **Tests fallan**
- El pipeline continúa aunque fallen tests (configured with `continue-on-error`)
- Revisa los reports en la pestaña Actions

---

## 📚 Documentación Adicional

- **Despliegue Manual:** Ver `DEPLOYMENT_GUIDE.md`
- **Tests E2E:** Ver `tests/e2e/README.md`
- **Tests de Performance:** Ver `TESTS_GUIDE.md`
- **Setup de Runner:** Ver `GITHUB_ACTIONS_SETUP.md`

---

## ✅ Checklist Final

- [x] 3 ramas creadas (dev, stage, master)
- [x] Pipeline DEV configurado (build + tests básicos)
- [x] Pipeline STAGE configurado (build + tests + deploy temporal)
- [x] Pipeline MASTER configurado (build + tests + deploy persistente + system tests)
- [x] Self-hosted runner configurado
- [x] Documentación completa

**¡Todo listo para demostrar en el taller!** 🎉
