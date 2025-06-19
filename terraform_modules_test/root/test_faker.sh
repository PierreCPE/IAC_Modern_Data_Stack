#!/bin/bash
set -e

echo "🧪 Test Faker → ADLS avec Airbyte OSS"
echo "=========================================="

# Vérifications préalables
echo "🔍 Vérification des prérequis..."

# 1. Vérifier Airbyte OSS
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "❌ Airbyte OSS n'est pas accessible"
    echo ""
    echo "📋 Pour démarrer Airbyte OSS :"
    echo "   git clone https://github.com/airbytehq/airbyte.git"
    echo "   cd airbyte"
    echo "   ./run-ab-platform.sh"
    echo ""
    echo "   Puis attendez que http://localhost:8000 soit accessible"
    exit 1
fi
echo "✅ Airbyte OSS accessible"

# 2. Vérifier Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI non installé"
    exit 1
fi

if ! az account show &> /dev/null 2>&1; then
    echo "🔑 Connexion à Azure requise..."
    az login
fi
echo "✅ Azure CLI configuré"

# 3. Initialiser Terraform
echo "🏗️ Initialisation Terraform..."
if [ ! -d ".terraform" ]; then
    terraform init
else
    echo "   Terraform déjà initialisé"
fi

# 4. Planifier le déploiement
echo "📋 Planification du déploiement..."
terraform plan -target=module.order-test -target=airbyte_source_faker.test_faker -target=airbyte_destination_azure_blob_storage.test_adls -target=airbyte_connection.faker_to_adls_test

# 5. Demander confirmation
echo ""
read -p "🚀 Voulez-vous déployer ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Déploiement annulé"
    exit 0
fi

# 6. Déployer
echo "🚀 Déploiement en cours..."
terraform apply -target=module.order-test -target=airbyte_source_faker.test_faker -target=airbyte_destination_azure_blob_storage.test_adls -target=airbyte_connection.faker_to_adls_test -auto-approve

# 7. Récupérer les outputs
echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "📊 Informations de déploiement :"
terraform output

echo ""
echo "🎯 Prochaines étapes pour tester :"
echo ""
echo "1. 🌐 Ouvrir l'interface Airbyte :"
echo "   http://localhost:8000"
echo "   Login: airbyte / password"
echo ""
echo "2. 🔄 Dans Airbyte, aller dans 'Connections'"
echo "   Trouver 'Faker to ADLS Test'"
echo "   Cliquer sur 'Sync now' pour déclencher manuellement"
echo ""
echo "3. 📁 Vérifier les données dans Azure :"
echo "   Resource Group: ModernDataStack"
echo "   Storage Account: $(terraform output -raw storage_account_name 2>/dev/null || echo 'pimdsdatalake')"
echo "   Container: foldercsv"
echo ""
echo "4. 📈 Surveiller le progress :"
echo "   Les logs du sync seront visibles dans l'UI Airbyte"
echo ""
echo "💡 Tip: La première sync peut prendre quelques minutes"
