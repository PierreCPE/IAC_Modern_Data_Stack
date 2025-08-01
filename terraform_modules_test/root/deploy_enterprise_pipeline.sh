#!/bin/bash
# Script Bash pour déployer le pipeline Azure Entreprise
# Usage: ./deploy_enterprise_pipeline.sh

set -e  # Exit on error

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Configuration Pipeline Azure Entreprise ===${NC}"

# Vérifier si .env existe
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Fichier .env non trouvé${NC}"
    echo -e "${YELLOW}📝 Créez un fichier .env basé sur .env.example avec votre connection string Azure${NC}"
    echo -e "${YELLOW}💡 Exemple: cp .env.example .env${NC}"
    exit 1
fi

# Charger les variables d'environnement depuis .env
echo -e "${BLUE}📁 Chargement des variables d'environnement...${NC}"
while IFS= read -r line; do
    # Ignorer les commentaires et lignes vides
    [[ $line =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Traiter les lignes export
    if [[ $line =~ ^export[[:space:]]+([^=]+)=(.*)$ ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_value="${BASH_REMATCH[2]}"
        
        # Supprimer les guillemets si présents
        var_value=$(echo "$var_value" | sed 's/^"\(.*\)"$/\1/')
        
        # Exporter la variable
        export "$var_name"="$var_value"
        echo -e "${GRAY}   ✓ $var_name configuré${NC}"
    fi
done < .env

# Vérifier la connection string
if [ -z "$TF_VAR_azure_connection_string" ]; then
    echo -e "${RED}❌ TF_VAR_azure_connection_string non définie${NC}"
    echo -e "${YELLOW}💡 Vérifiez votre fichier .env${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Variables d'environnement chargées${NC}"

# Vérifier que terraform est installé
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform n'est pas installé${NC}"
    echo -e "${YELLOW}💡 Installez Terraform: https://www.terraform.io/downloads${NC}"
    exit 1
fi

# Initialiser Terraform
echo -e "${BLUE}🏗️  Initialisation Terraform...${NC}"
if ! terraform init; then
    echo -e "${RED}❌ Erreur lors de l'initialisation Terraform${NC}"
    exit 1
fi

# Planifier le déploiement
echo -e "${BLUE}📋 Planification du déploiement...${NC}"
if ! terraform plan -out=tfplan; then
    echo -e "${RED}❌ Erreur lors de la planification${NC}"
    exit 1
fi

# Demander confirmation
echo ""
read -p "🚀 Voulez-vous appliquer ce plan ? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🚀 Application du plan...${NC}"
    
    if terraform apply tfplan; then
        echo ""
        echo -e "${GREEN}✅ Déploiement réussi !${NC}"
        echo ""
        echo -e "${BLUE}📊 Informations du pipeline :${NC}"
        terraform output connection_info
        echo ""
        echo -e "${BLUE}🔗 Prochaines étapes :${NC}"
        terraform output deployment_info
        
        # Nettoyer le plan
        rm -f tfplan
    else
        echo -e "${RED}❌ Erreur lors du déploiement${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}❌ Déploiement annulé${NC}"
    rm -f tfplan
fi

echo ""
echo -e "${CYAN}🎯 Pipeline configuré :${NC}"
echo -e "${WHITE}   [Azure Blob: source-test] --> (Airbyte) --> [Azure Blob: raw-data]${NC}"
echo ""
echo -e "${YELLOW}📝 Prochaine étape : Configurer Azure Function pour [raw-data] --> [parquet]${NC}"

# Afficher les informations utiles
echo ""
echo -e "${BLUE}📋 Informations utiles :${NC}"
echo -e "${GRAY}   • Interface Airbyte : http://localhost:8000${NC}"
echo -e "${GRAY}   • Login Airbyte : airbyte / password${NC}"
echo -e "${GRAY}   • Containers Azure : source-test → raw-data → parquet${NC}"
echo ""
echo -e "${GREEN}🎉 Configuration terminée avec succès !${NC}"
