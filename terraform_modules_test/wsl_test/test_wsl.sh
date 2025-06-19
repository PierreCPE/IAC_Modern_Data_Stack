#!/bin/bash
set -e

echo "🐧 WSL Test: Faker → ADLS avec Airbyte OSS"
echo "============================================="

# Détection WSL
if grep -q microsoft /proc/version; then
    echo "✅ WSL détecté"
    IS_WSL=true
else
    echo "ℹ️ Linux standard"
    IS_WSL=false
fi

# 1. Test Airbyte
echo "🔍 Test connectivité Airbyte..."
AIRBYTE_URL=""

if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    AIRBYTE_URL="http://localhost:8000"
    echo "✅ Airbyte → localhost:8000"
elif [ "$IS_WSL" = true ]; then
    WINDOWS_IP=$(ip route show | grep -i default | awk '{ print $3}')
    if [ -n "$WINDOWS_IP" ] && curl -s http://$WINDOWS_IP:8000/health > /dev/null 2>&1; then
        AIRBYTE_URL="http://$WINDOWS_IP:8000"
        echo "✅ Airbyte → $WINDOWS_IP:8000"
    fi
fi

if [ -z "$AIRBYTE_URL" ]; then
    echo "❌ Airbyte non accessible"
    echo "💡 Démarrer Airbyte dans WSL:"
    echo "   git clone https://github.com/airbytehq/airbyte.git"
    echo "   cd airbyte && ./run-ab-platform.sh"
    exit 1
fi

# 2. Azure CLI
echo "🔑 Authentification Azure..."
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI manquant"
    exit 1
fi

if ! az account show &> /dev/null; then
    echo "🔐 Device code login..."
    az login --use-device-code
fi

ACCOUNT=$(az account show --query '{subscription:id, tenant:tenantId, user:user.name}' -o json)
echo "✅ Azure connecté:"
echo "   $(echo $ACCOUNT | jq -r '.user')"
echo "   $(echo $ACCOUNT | jq -r '.subscription')"

# 3. Variables Terraform
export TF_VAR_airbyte_server_url="$AIRBYTE_URL"
export ARM_USE_CLI=true

# 4. Terraform
echo "🏗️ Terraform..."
terraform init

echo "📋 Plan (storage d'abord)..."
terraform plan -target=module.storage

read -p "🚀 Déployer le storage Azure ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Déploiement storage..."
    terraform apply -target=module.storage -auto-approve
    
    echo "📋 Plan Airbyte..."
    terraform plan
    
    read -p "🚀 Configurer Airbyte ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 Configuration Airbyte..."
        terraform apply -auto-approve
        
        echo ""
        echo "🎉 Déploiement terminé !"
        terraform output
        echo ""
        echo "🌐 Interface Airbyte: $AIRBYTE_URL"
        echo "🔑 Login: airbyte / password"
        echo "🔄 Connection: WSL Faker to ADLS"
    fi
else
    echo "❌ Arrêté"
fi
