#!/bin/bash
set -e

echo "🚀 Déploiement du Modern Data Stack avec Airbyte"

# Vérification des prérequis
echo "🔍 Vérification des prérequis..."

# Vérifier que Airbyte OSS fonctionne
if ! curl -s http://localhost:8000 > /dev/null; then
    echo "❌ Airbyte n'est pas accessible sur http://localhost:8000"
    echo "   Démarrez Airbyte avec :"
    echo "   git clone https://github.com/airbytehq/airbyte.git"
    echo "   cd airbyte"
    echo "   ./run-ab-platform.sh"
    exit 1
fi

echo "✅ Airbyte OSS détecté"

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

# Configuration optionnelle GCS
if [ -n "$GCS_BUCKET_NAME" ] && [ -n "$GCS_SERVICE_ACCOUNT_KEY" ]; then
    echo "🗂️ Configuration GCS détectée"
    export TF_VAR_gcs_bucket_name="$GCS_BUCKET_NAME"
    export TF_VAR_gcs_service_account_key="$GCS_SERVICE_ACCOUNT_KEY"
    echo "✅ Variables GCS configurées"
fi

# Déploiement Terraform
echo "🏗️ Initialisation Terraform..."
terraform init

echo "📋 Planification du déploiement..."
terraform plan

echo "🚀 Déploiement de l'infrastructure..."
terraform apply -auto-approve

echo ""
echo "✅ Déploiement terminé avec succès !"
echo ""
echo "📊 Ressources créées :"
echo "   - Resource Group : ModernDataStack"
echo "   - Storage Account : pimdsdatalake"
echo "   - Containers : foldercsv, folderparquet, rootmoduletest"
echo "   - Data Factory : pimdsdatafactory"
echo "   - Airbyte Sources : Faker + GCS (si configuré)"
echo "   - Airbyte Destinations : Azure Blob Storage"
echo "   - Airbyte Connections : Pipelines configurés"
echo ""
echo "🌐 Accès aux services :"
echo "   - Airbyte UI    : http://localhost:8000"
echo "   - Azure Portal  : https://portal.azure.com"
echo ""
echo "📝 Prochaines étapes :"
echo "   1. Vérifiez les connexions dans l'UI Airbyte"
echo "   2. Déclenchez un sync manuel pour tester"
echo "   3. Vérifiez les données dans Azure Storage"
