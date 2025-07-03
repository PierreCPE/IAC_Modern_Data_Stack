# 🚀 Déploiement Rapide - Pipeline Azure Entreprise

## 🎯 Pipeline Cible
```
[Azure Blob: source-test] → (Airbyte) → [Azure Blob: raw-data] → (Azure Function) → [Azure Blob: parquet]
```

## ⚡ Déploiement en 3 étapes

### 1. Configuration
```bash
# Copier le template de configuration
cp .env.example .env

# Éditer avec votre connection string Azure
nano .env  # ou vim .env, ou code .env
```

**Dans `.env`, remplacez :**
```bash
export TF_VAR_azure_connection_string="DefaultEndpointsProtocol=https;AccountName=VOTRE_STORAGE_ACCOUNT;AccountKey=VOTRE_CLE;EndpointSuffix=core.windows.net"
```

### 2. Déploiement

#### Script Bash (Recommandé pour Linux/WSL)
```bash
chmod +x deploy_enterprise_pipeline.sh
./deploy_enterprise_pipeline.sh
```

### 3. Utilisation
```bash
# 1. Ouvrir Airbyte
http://localhost:8000

# 2. Login : airbyte / password

# 3. Lancer la synchronisation
# Connections → "Enterprise Blob to Raw Data" → Sync now
```

## 📁 Containers Azure Requis

Assurez-vous que ces containers existent :
- ✅ **source-test** : Vos données source
- ✅ **raw-data** : Créé automatiquement par Airbyte
- ✅ **parquet** : Pour l'étape suivante (Azure Function)

## 🔍 Vérification

Après déploiement, vérifiez :
1. Interface Airbyte accessible : http://localhost:8000
2. Connection "Enterprise Blob to Raw Data" créée
3. Synchronisation manuelle fonctionne
4. Données apparaissent dans `raw-data`

## 🚨 En cas de problème

```bash
# Logs Terraform
terraform show

# Validation config
terraform validate
```
