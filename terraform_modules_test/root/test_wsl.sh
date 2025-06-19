#!/bin/bash
set -e

echo "🐧 WSL Test: Faker → ADLS avec Airbyte OSS"
echo "============================================="

# Détection de l'environnement WSL
if grep -q microsoft /proc/version; then
    echo "✅ Environnement WSL détecté"
    IS_WSL=true
else
    echo "ℹ️ Environnement Linux standard"
    IS_WSL=false
fi

# Vérifications préalables
echo "🔍 Vérification des prérequis..."

# 1. Vérifier Airbyte OSS (adapté WSL)
echo "🔍 Test connectivité Airbyte..."
AIRBYTE_URL=""

# Tests de connectivité par ordre de préférence
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    AIRBYTE_URL="http://localhost:8000"
    echo "✅ Airbyte accessible via localhost"
elif [ "$IS_WSL" = true ]; then
    # IP de l'hôte Windows depuis WSL
    WINDOWS_IP=$(ip route show | grep -i default | awk '{ print $3}')
    if [ -n "$WINDOWS_IP" ] && curl -s http://$WINDOWS_IP:8000/health > /dev/null 2>&1; then
        AIRBYTE_URL="http://$WINDOWS_IP:8000"
        echo "✅ Airbyte accessible via IP Windows: $WINDOWS_IP"
    fi
fi

if [ -z "$AIRBYTE_URL" ]; then
    echo "❌ Airbyte non accessible depuis WSL"
    echo ""
    echo "🔧 Solutions:"
    echo "1. Démarrer Airbyte dans WSL:"
    echo "   git clone https://github.com/airbytehq/airbyte.git"
    echo "   cd airbyte && ./run-ab-platform.sh"
    echo ""
    echo "2. Ou configurer port forwarding Windows:"
    echo "   netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=127.0.0.1"
    exit 1
fi

# 2. Vérifier Azure CLI et authentification
echo "🔑 Vérification Azure CLI..."
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI non trouvé"
    echo "Installation: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

# Test de l'authentification Azure avec debug
echo "🔍 Test de l'authentification Azure..."
if ! az account show &> /dev/null; then
    echo "❌ Non connecté à Azure"
    
    if [ "$IS_WSL" = true ]; then
        echo ""
        echo "🔧 Authentification Azure en WSL:"
        echo "1. Utilisation du device code (recommandé pour WSL):"
        echo ""
        az login --use-device-code
    else
        echo "🔑 Connexion Azure standard..."
        az login
    fi
    
    # Re-vérifier après login
    if ! az account show &> /dev/null; then
        echo "❌ Échec de la connexion Azure"
        exit 1
    fi
fi

# Afficher les infos de compte pour debug
ACCOUNT_INFO=$(az account show --output json 2>/dev/null)
SUBSCRIPTION_ID=$(echo $ACCOUNT_INFO | jq -r '.id')
TENANT_ID=$(echo $ACCOUNT_INFO | jq -r '.tenantId')
USER_NAME=$(echo $ACCOUNT_INFO | jq -r '.user.name // .user.assignedIdentityInfo // "unknown"')

echo "✅ Azure CLI configuré:"
echo "   👤 Utilisateur: $USER_NAME"
echo "   🏢 Tenant: $TENANT_ID"
echo "   📋 Subscription: $SUBSCRIPTION_ID"

# 3. Variables d'environnement pour Terraform
echo "🔧 Configuration des variables Terraform..."
export ARM_USE_CLI=true
export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export ARM_TENANT_ID="$TENANT_ID"
export TF_VAR_airbyte_server_url="$AIRBYTE_URL"

echo "✅ Variables configurées:"
echo "   🌐 Airbyte URL: $AIRBYTE_URL"
echo "   🔑 Azure Auth: CLI"

# 4. Terraform
echo "🏗️ Initialisation Terraform..."
if [ ! -d ".terraform" ]; then
    terraform init
else
    echo "   ↻ Terraform déjà initialisé"
fi

# 5. Plan avec validation
echo "📋 Validation de la configuration..."
if ! terraform validate; then
    echo "❌ Configuration Terraform invalide"
    exit 1
fi

echo "📋 Planification du déploiement (stockage seulement pour commencer)..."
if ! terraform plan -target=module.order-test -out=tfplan; then
    echo "❌ Erreur lors de la planification"
    echo ""
    echo "🔍 Vérifications suggérées:"
    echo "1. Permissions Azure: az role assignment list --assignee $USER_NAME"
    echo "2. Quota Azure: az vm list-usage --location francecentral"
    echo "3. Provider version: terraform version"
    exit 1
fi

# 6. Demander confirmation
echo ""
echo "🎯 Prêt à déployer:"
echo "   📦 Resource Group: ModernDataStack"
echo "   💾 Storage Account: pimdsdatalake"
echo "   🌍 Région: France Central"
echo ""
read -p "🚀 Continuer avec le déploiement ? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Déploiement annulé"
    rm -f tfplan
    exit 0
fi

# 7. Déploiement étape par étape
echo "🚀 Déploiement de l'infrastructure Azure..."
if terraform apply tfplan; then
    echo "✅ Infrastructure Azure déployée"
    rm -f tfplan
else
    echo "❌ Échec du déploiement Azure"
    rm -f tfplan
    exit 1
fi

# 8. Configuration Airbyte (séparée pour éviter les conflits)
echo ""
echo "🔄 Configuration Airbyte..."
read -p "🎯 Configurer maintenant Airbyte ? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Déploiement des ressources Airbyte..."
    terraform apply -target=airbyte_source_faker.test_faker -target=airbyte_destination_azure_blob_storage.test_adls -target=airbyte_connection.faker_to_adls_test -auto-approve
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Déploiement complet réussi !"
        terraform output
        echo ""
        echo "📱 Prochaines étapes:"
        echo "1. 🌐 Interface Airbyte: $AIRBYTE_URL"
        echo "2. 🔑 Login: airbyte / password"
        echo "3. 🔄 Connexions → 'Faker to ADLS Test' → 'Sync now'"
        echo "4. 🌍 Azure: https://portal.azure.com → ModernDataStack"
    else
        echo "⚠️ Erreur configuration Airbyte (infrastructure Azure OK)"
    fi
else
    echo "ℹ️ Infrastructure Azure prête. Configurez Airbyte manuellement si nécessaire."
fi
