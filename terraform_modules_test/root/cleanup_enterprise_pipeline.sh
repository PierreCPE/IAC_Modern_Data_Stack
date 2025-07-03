#!/bin/bash
# Script de nettoyage pour le pipeline Azure Entreprise
# Usage: ./cleanup_enterprise_pipeline.sh

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Nettoyage Pipeline Azure Entreprise ===${NC}"

# Vérifier si .env existe pour charger les variables
if [ -f ".env" ]; then
    echo -e "${BLUE}📁 Chargement des variables d'environnement...${NC}"
    while IFS= read -r line; do
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        if [[ $line =~ ^export[[:space:]]+([^=]+)=(.*)$ ]]; then
            var_name="${BASH_REMATCH[1]}"
            var_value="${BASH_REMATCH[2]}"
            var_value=$(echo "$var_value" | sed 's/^"\(.*\)"$/\1/')
            export "$var_name"="$var_value"
        fi
    done < .env
fi

# Demander confirmation
echo -e "${YELLOW}⚠️  Cette action va détruire toutes les ressources Terraform créées${NC}"
echo -e "${YELLOW}💡 Les données dans vos containers Azure ne seront PAS supprimées${NC}"
echo ""
read -p "🗑️  Voulez-vous vraiment détruire l'infrastructure ? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🗑️  Destruction de l'infrastructure...${NC}"
    
    if terraform destroy -auto-approve; then
        echo ""
        echo -e "${GREEN}✅ Infrastructure détruite avec succès !${NC}"
        
        # Nettoyer les fichiers temporaires
        echo -e "${BLUE}🧹 Nettoyage des fichiers temporaires...${NC}"
        rm -f tfplan
        rm -f terraform.tfstate.backup
        
        echo -e "${GREEN}🎉 Nettoyage terminé !${NC}"
        echo ""
        echo -e "${BLUE}📋 Ce qui a été conservé :${NC}"
        echo -e "${GRAY}   • Vos données dans les containers Azure${NC}"
        echo -e "${GRAY}   • Le fichier .env avec votre connection string${NC}"
        echo -e "${GRAY}   • Les fichiers de configuration Terraform${NC}"
        echo ""
        echo -e "${YELLOW}💡 Pour redéployer : ./deploy_enterprise_pipeline.sh${NC}"
    else
        echo -e "${RED}❌ Erreur lors de la destruction${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Destruction annulée${NC}"
fi
