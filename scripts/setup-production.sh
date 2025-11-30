#!/bin/bash

# Script de Setup Rápido para Producción
# Este script te guiará paso a paso en la configuración inicial

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Setup de Producción - Ecommerce${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verificar Azure CLI
echo -e "${YELLOW}[1/7] Verificando Azure CLI...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI no está instalado${NC}"
    echo -e "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi
echo -e "${GREEN}✓ Azure CLI instalado${NC}"

# Login a Azure
echo ""
echo -e "${YELLOW}[2/7] Login a Azure...${NC}"
az account show &> /dev/null || az login
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
echo -e "${GREEN}✓ Conectado a Azure${NC}"
echo -e "  Subscription: ${SUBSCRIPTION_ID}"
echo -e "  Tenant: ${TENANT_ID}"

# Crear Service Principal
echo ""
echo -e "${YELLOW}[3/7] Crear Service Principal...${NC}"
read -p "¿Crear Service Principal para GitHub Actions? (y/n): " create_sp
if [ "$create_sp" = "y" ]; then
    echo "Creando Service Principal..."
    SP_JSON=$(az ad sp create-for-rbac \
        --name "github-actions-ecommerce-$(date +%s)" \
        --role contributor \
        --scopes /subscriptions/$SUBSCRIPTION_ID \
        --sdk-auth)
    
    echo ""
    echo -e "${GREEN}✓ Service Principal creado${NC}"
    echo ""
    echo -e "${BLUE}Guarda este JSON como secret AZURE_CREDENTIALS en GitHub:${NC}"
    echo "$SP_JSON"
    echo ""
    read -p "Presiona Enter cuando hayas copiado el JSON..."
fi

# Crear IP Estática
echo ""
echo -e "${YELLOW}[4/7] Crear IP Estática...${NC}"
read -p "¿Crear IP estática para el Load Balancer? (y/n): " create_ip
if [ "$create_ip" = "y" ]; then
    read -p "Location (default: eastus): " location
    location=${location:-eastus}
    
    echo "Creando resource group..."
    az group create \
        --name ecommerce-static-resources \
        --location $location
    
    echo "Creando IP pública estática..."
    az network public-ip create \
        --resource-group ecommerce-static-resources \
        --name ecommerce-prod-ip \
        --sku Standard \
        --allocation-method Static \
        --location $location
    
    STATIC_IP=$(az network public-ip show \
        --resource-group ecommerce-static-resources \
        --name ecommerce-prod-ip \
        --query ipAddress \
        --output tsv)
    
    echo ""
    echo -e "${GREEN}✓ IP Estática creada${NC}"
    echo -e "  IP: ${STATIC_IP}"
    echo ""
    echo -e "${BLUE}Guarda esta IP como secret PROD_STATIC_IP en GitHub${NC}"
    echo ""
    read -p "Presiona Enter para continuar..."
fi

# Crear Storage Account para Terraform
echo ""
echo -e "${YELLOW}[5/7] Crear Storage Account para Terraform...${NC}"
read -p "¿Crear Storage Account para el state de Terraform? (y/n): " create_storage
if [ "$create_storage" = "y" ]; then
    read -p "Location (default: eastus): " location
    location=${location:-eastus}
    
    echo "Creando resource group..."
    az group create \
        --name ecommerce-terraform-state \
        --location $location
    
    echo "Creando storage account..."
    az storage account create \
        --name ecomtfstateprod \
        --resource-group ecommerce-terraform-state \
        --location $location \
        --sku Standard_LRS \
        --encryption-services blob
    
    echo "Creando container..."
    az storage container create \
        --name tfstate \
        --account-name ecomtfstateprod
    
    echo ""
    echo -e "${GREEN}✓ Storage Account creado${NC}"
    echo ""
    read -p "Presiona Enter para continuar..."
fi

# Configurar Dominio
echo ""
echo -e "${YELLOW}[6/7] Configuración de Dominio...${NC}"
echo ""
if [ "$create_ip" = "y" ]; then
    echo -e "${BLUE}Configuración de DNS:${NC}"
    echo "1. Ve a tu proveedor de DNS"
    echo "2. Crea un registro A:"
    echo "   - Host: ecommerce (o @)"
    echo "   - Tipo: A"
    echo "   - Valor: $STATIC_IP"
    echo "   - TTL: 3600"
    echo ""
fi

read -p "¿Tienes un dominio configurado? (y/n): " has_domain
if [ "$has_domain" = "y" ]; then
    read -p "Ingresa tu dominio (ej: ecommerce.tudominio.com): " domain
    
    echo ""
    echo -e "${BLUE}Actualizando values-prod.yaml...${NC}"
    sed -i "s/yourdomain.com/$domain/g" infra/terraform/environments/prod/values-prod.yaml
    echo -e "${GREEN}✓ Dominio actualizado en values-prod.yaml${NC}"
else
    domain="[IP-DEL-LOAD-BALANCER]"
    echo -e "${YELLOW}! Usarás la IP del Load Balancer${NC}"
fi

# Resumen de Secrets
echo ""
echo -e "${YELLOW}[7/7] Resumen de Secrets de GitHub...${NC}"
echo ""
echo -e "${BLUE}Configura estos secrets en GitHub:${NC}"
echo -e "Settings → Secrets and variables → Actions → New repository secret"
echo ""
echo "┌────────────────────────────┬─────────────────────────────────┐"
echo "│ Secret Name                │ Valor                           │"
echo "├────────────────────────────┼─────────────────────────────────┤"
echo "│ AZURE_CREDENTIALS          │ [JSON del Service Principal]    │"
echo "│ AZURE_SUBSCRIPTION_ID      │ $SUBSCRIPTION_ID │"
echo "│ AZURE_TENANT_ID            │ $TENANT_ID │"
echo "│ JWT_SECRET                 │ [Tu secret JWT]                 │"
echo "│ GRAFANA_ADMIN_PASSWORD     │ [Tu password de Grafana]        │"
echo "│ LETSENCRYPT_EMAIL          │ [Tu email]                      │"
echo "│ PROD_DOMAIN                │ $domain                         │"
if [ "$create_ip" = "y" ]; then
echo "│ PROD_STATIC_IP             │ $STATIC_IP                      │"
fi
echo "└────────────────────────────┴─────────────────────────────────┘"

# Guardar información
echo ""
echo -e "${BLUE}Guardando información...${NC}"
cat > setup-info.txt << EOF
# Información de Setup - $(date)

## Azure
Subscription ID: $SUBSCRIPTION_ID
Tenant ID: $TENANT_ID

## Recursos Creados
EOF

if [ "$create_ip" = "y" ]; then
    echo "IP Estática: $STATIC_IP" >> setup-info.txt
    echo "Resource Group (IP): ecommerce-static-resources" >> setup-info.txt
fi

if [ "$create_storage" = "y" ]; then
    echo "Storage Account: ecomtfstateprod" >> setup-info.txt
    echo "Resource Group (Storage): ecommerce-terraform-state" >> setup-info.txt
fi

echo "" >> setup-info.txt
echo "## Dominio" >> setup-info.txt
echo "Domain: $domain" >> setup-info.txt

echo ""
echo -e "${GREEN}✓ Información guardada en setup-info.txt${NC}"

# Final
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}   ✅ Setup Completado!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo ""
echo "1. Configura todos los secrets en GitHub"
echo "2. Revisa el archivo: SETUP-PRODUCTION-MONITORING.md"
echo "3. Verifica el archivo: setup-info.txt"
echo "4. Haz push a master para desplegar:"
echo ""
echo "   git add ."
echo "   git commit -m 'feat: Setup production monitoring'"
echo "   git push origin master"
echo ""
echo -e "${GREEN}¡Listo para desplegar! 🚀${NC}"
echo ""
