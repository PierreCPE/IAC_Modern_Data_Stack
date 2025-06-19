#!/bin/bash
# Script de test du pipeline d'ingestion Faker → ADLS
# Basé sur la logique validée du test WSL

set -e

echo "🧪 Test du pipeline d'ingestion Faker → ADLS"
echo "   Mode : Production (module principal)"

# Fonction de vérification d'URL
check_url() {
    local url=$1
    local service=$2
    echo "🔍 Vérification de $service..."
    if curl -s "$url" > /dev/null; then
        echo "✅ $service accessible sur $url"
        return 0
    else
        echo "❌ $service non accessible sur $url"
        return 1
    fi
}

# Fonction de vérification Azure
check_azure_connection() {
    echo "🔍 Vérification de la connexion Azure..."
    if az account show &> /dev/null; then
        local account=$(az account show --query name -o tsv)
        echo "✅ Connecté à Azure : $account"
        return 0
    else
        echo "❌ Non connecté à Azure"
        return 1
    fi
}

# Fonction de récupération des outputs Terraform
get_terraform_outputs() {
    echo "📊 Récupération des informations de déploiement..."
    
    if [ ! -f "terraform.tfstate" ]; then
        echo "❌ Fichier terraform.tfstate introuvable"
        echo "   Exécutez d'abord le déploiement avec ./deploy.sh"
        return 1
    fi
    
    echo "✅ État Terraform trouvé"
    
    # Récupération des outputs
    STORAGE_ACCOUNT=$(terraform output -raw connection_info 2>/dev/null | jq -r '.storage_account' 2>/dev/null || echo "unknown")
    CONTAINER=$(terraform output -raw connection_info 2>/dev/null | jq -r '.container' 2>/dev/null || echo "foldercsv")
    CONNECTION_ID=$(terraform output -raw airbyte_connection_id 2>/dev/null || echo "unknown")
    
    echo "   - Storage Account: $STORAGE_ACCOUNT"
    echo "   - Container: $CONTAINER"
    echo "   - Connection ID: $CONNECTION_ID"
}

# Fonction de test Airbyte
test_airbyte_connection() {
    echo "🔄 Test de la connexion Airbyte..."
    
    local airbyte_url="http://localhost:8000"
    
    # Test de l'API Airbyte
    if ! curl -s "$airbyte_url/api/v1/health" > /dev/null; then
        echo "❌ API Airbyte non accessible"
        return 1
    fi
    
    echo "✅ API Airbyte accessible"
    
    # Affichage des informations de connexion
    echo "📝 Informations pour test manuel :"
    echo "   1. Ouvrir $airbyte_url"
    echo "   2. Login: airbyte / password"
    echo "   3. Aller dans Connections"
    echo "   4. Chercher 'Production Faker to ADLS'"
    echo "   5. Cliquer 'Sync now'"
    echo "   6. Attendre la fin du sync"
}

# Fonction de vérification Azure Storage
check_azure_storage() {
    echo "☁️ Vérification du stockage Azure..."
    
    if [ "$STORAGE_ACCOUNT" = "unknown" ]; then
        echo "⚠️ Nom du storage account non trouvé dans les outputs"
        return 1
    fi
    
    # Vérification de l'existence du storage account
    if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "ModernDataStack" &> /dev/null; then
        echo "✅ Storage account '$STORAGE_ACCOUNT' trouvé"
        
        # Vérification du container
        if az storage container show --name "$CONTAINER" --account-name "$STORAGE_ACCOUNT" &> /dev/null; then
            echo "✅ Container '$CONTAINER' trouvé"
            
            # Liste des fichiers (si il y en a)
            echo "📂 Contenu du container '$CONTAINER' :"
            az storage blob list --container-name "$CONTAINER" --account-name "$STORAGE_ACCOUNT" --query "[].name" -o table 2>/dev/null || echo "   (Aucun fichier pour le moment)"
        else
            echo "❌ Container '$CONTAINER' non trouvé"
            return 1
        fi
    else
        echo "❌ Storage account '$STORAGE_ACCOUNT' non trouvé"
        return 1
    fi
}

# Fonction de monitoring
monitor_sync() {
    echo "📊 Suggestions de monitoring :"
    echo "   - Airbyte UI : http://localhost:8000/connections"
    echo "   - Azure Portal : https://portal.azure.com → ModernDataStack → $STORAGE_ACCOUNT"
    echo "   - Logs Terraform : ./terraform.log"
    echo ""
    echo "🔄 Pour déclencher un nouveau sync :"
    echo "   1. Via UI : Connections → 'Production Faker to ADLS' → Sync now"
    echo "   2. Via API : curl -X POST http://localhost:8000/api/v1/connections/$CONNECTION_ID/sync"
}

# Fonction principale
main() {
    echo "=========================================="
    echo "🧪 TEST PIPELINE FAKER → ADLS"
    echo "=========================================="
    
    # Tests des prérequis
    check_url "http://localhost:8000" "Airbyte OSS" || exit 1
    check_azure_connection || exit 1
    
    # Récupération des informations
    get_terraform_outputs || exit 1
    
    # Tests de l'infrastructure
    test_airbyte_connection
    check_azure_storage
    
    # Monitoring
    monitor_sync
    
    echo ""
    echo "✅ Tests terminés"
    echo "🎉 Pipeline prêt pour l'ingestion !"
    echo ""
    echo "📝 Prochaines étapes :"
    echo "   1. Déclencher un sync via l'UI Airbyte"
    echo "   2. Vérifier les données dans Azure Storage"
    echo "   3. Configurer un scheduling automatique si besoin"
}

# Exécution
main "$@"
