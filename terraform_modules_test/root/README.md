# Module Terraform : Modern Data Stack - Pipeline Faker vers ADLS

## Architecture

Ce module Terraform déploie un **Modern Data Stack** complet avec pipeline d'ingestion **Faker → ADLS** basé sur la logique validée du test WSL.

### **Infrastructure Azure**
- **Resource Group** : `ModernDataStack`
- **Storage Account** : `pimdsdatalake` (ADLS Gen2)
- **Containers** : `foldercsv`, `folderparquet`, `rootmoduletest`
- **Data Factory** : `pimdsdatafactory` avec pipeline CSV → Parquet

### **Pipeline d'Ingestion Airbyte OSS**
- **Source Faker** : Génération de 1000 enregistrements de données de test (users, products, purchases)
- **Destination Azure** : Export vers ADLS Gen2 en format CSV
- **Connexion** : Pipeline automatisé Faker → ADLS avec namespace "production_data"
- **Configurabilité** : Support GCS optionnel pour compatibilité

## Prérequis

### **1. Airbyte OSS Local**
```bash
# Option 1: Via Git Clone
git clone https://github.com/airbytehq/airbyte.git
cd airbyte
./run-ab-platform.sh

# Option 2: Via Docker Compose (dans ce projet)
docker-compose up -d
```
Airbyte sera accessible sur http://localhost:8000 (airbyte/password)

### **2. Azure CLI**
```bash
# Installation (Windows)
winget install Microsoft.AzureCLI

# Connexion
az login
```

### **3. Terraform**
- Terraform >= 1.1.0
- Provider azurerm ~> 3.0.2
- Provider airbyte ~> 0.6.0

## Utilisation

### **Déploiement rapide**

#### **Windows PowerShell**
```powershell
cd terraform_modules_test/root
.\deploy.ps1
```

#### **Linux/WSL/Bash**
```bash
cd terraform_modules_test/root
chmod +x deploy.sh
./deploy.sh
```

### **Déploiement avec GCS**
```bash
# 1. Configurer les variables GCS
export GCS_BUCKET_NAME="votre-bucket-gcs"
export GCS_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'

# 2. Déployer
./deploy.sh
```

### **Déploiement manuel**
```bash
terraform init
terraform plan
terraform apply
```

## Configuration GCS (Optionnel)

### **1. Créer un Service Account GCS**
```bash
# Créer le service account
gcloud iam service-accounts create airbyte-reader \
    --description="Airbyte GCS Reader" \
    --display-name="Airbyte GCS Reader"

# Donner les permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:airbyte-reader@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectViewer"

# Créer la clé
gcloud iam service-accounts keys create ~/gcs-key.json \
    --iam-account=airbyte-reader@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### **2. Configurer les variables**
```bash
export GCS_BUCKET_NAME="votre-bucket-csv"
export GCS_SERVICE_ACCOUNT_KEY=$(cat ~/gcs-key.json | tr -d '\n')
```

## Flux de données

```
Source Faker → Airbyte → Azure Blob (CSV) → Data Factory → Azure Blob (Parquet)
     ↓
Source GCS → Airbyte → Azure Blob (Parquet)
```

## Vérification

### **1. Airbyte UI**
- Accès : http://localhost:8000
- Credentials : `airbyte` / `password`
- Vérifiez les sources, destinations et connexions

### **2. Azure Portal**
- Resource Group : `ModernDataStack`
- Storage Account : `pimdsdatalake`
- Containers : Vérifiez les fichiers CSV et Parquet

### **3. Logs Terraform**
```bash
terraform output airbyte_faker_source_id
terraform output airbyte_azure_destination_id
```

## 🛠️ Structure des modules

```
root/
├── main.tf                    # Configuration principale
├── deploy.sh                  # Script de déploiement
├── .env.example              # Configuration d'exemple
└── modules/
    ├── order-test/           # Module stockage Azure existant
    │   └── submodules/azure-datalake/
    └── airbyte-ingestion/    # Module Airbyte nouveau
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── submodules/
            ├── airbyte-sources/
            └── airbyte-connections/
```