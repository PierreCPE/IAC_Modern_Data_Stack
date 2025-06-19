#!/bin/bash
set -e

echo "🚀 Déploiement du Modern Data Stack - Pipeline Faker vers ADLS"
echo "   Basé sur la logique validée du test WSL"

# Vérification des prérequis
echo "🔍 Vérification des prérequis..."

# Vérifier que Airbyte OSS fonctionne
echo "🔍 Vérification d'Airbyte OSS..."
if ! curl -s http://localhost:8000 > /dev/null; then
    echo "❌ Airbyte n'est pas accessible sur http://localhost:8000"
    echo "   Démarrez Airbyte avec :"
    echo "   cd /path/to/airbyte"
    echo "   ./run-ab-platform.sh"
    echo "   Ou via Docker Compose dans ce projet :"
    echo "   docker-compose up -d"
    exit 1
fi

echo "✅ Airbyte OSS détecté sur http://localhost:8000"

# Vérifier Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI non trouvé. Installez-le depuis https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Connexion Azure
echo "🔑 Vérification de la connexion Azure..."
if ! az account show &> /dev/null; then
    echo "🔑 Connexion à Azure..."
    az login
fi

echo "✅ Connexion Azure OK"

# Variables d'environnement pour optimiser Terraform
export TF_LOG=INFO
export TF_LOG_PATH="./terraform.log"

# Configuration Airbyte
export TF_VAR_airbyte_server_url="http://localhost:8000"
export TF_VAR_workspace_id="5ae6b09b-fdec-41af-aed7-204436cc6af6"

# Configuration optionnelle GCS (pour compatibilité)
if [ -n "$GCS_BUCKET_NAME" ] && [ -n "$GCS_SERVICE_ACCOUNT_KEY" ]; then
    echo "🗂️ Configuration GCS détectée"
    export TF_VAR_gcs_bucket_name="$GCS_BUCKET_NAME"
    export TF_VAR_gcs_service_account_key="$GCS_SERVICE_ACCOUNT_KEY"
    echo "✅ Variables GCS configurées"
fi

# Déploiement Terraform en séquence (inspiré du test WSL)
echo "🏗️ Initialisation Terraform..."
terraform init

echo "📋 Planification du déploiement..."
terraform plan -out=tfplan

# Déploiement séquencé pour éviter les problèmes de dépendances
echo "🏗️ Étape 1/2 : Déploiement du stockage Azure..."
terraform apply -target="module.order-test" -auto-approve

echo "🏗️ Étape 2/2 : Déploiement du pipeline Airbyte..."
terraform apply -auto-approve

echo ""
echo "✅ Déploiement terminé avec succès !"
echo ""

# Affichage des informations de déploiement
echo "📊 Informations du déploiement :"
terraform output -json deployment_info | jq -r '.value.next_steps[]'

echo ""
echo "🔗 Accès aux services :"
echo "   - Airbyte UI    : http://localhost:8000 (airbyte/password)"
echo "   - Azure Portal  : https://portal.azure.com"

echo ""
echo "📂 Informations du stockage :"
terraform output storage_info

echo ""
echo "🔄 Informations de la connexion :"
terraform output connection_info

echo ""
echo "📝 Test du pipeline :"
echo "   1. Ouvrir http://localhost:8000"
echo "   2. Login: airbyte / password"
echo "   3. Aller dans Connections"
echo "   4. Chercher 'Production Faker to ADLS'"
echo "   5. Cliquer 'Sync now'"
echo "   6. Vérifier les données dans Azure Portal"

echo ""
echo "🎉 Pipeline prêt pour l'ingestion Faker → ADLS !"
