# 🐧 Test WSL - Guide d'utilisation

## 🎯 Objectif
Tester l'ingestion Faker → ADLS dans un environnement WSL propre, sans conflits de configuration.

## 📁 Structure
```
terraform_modules_test/
├── root/                    # Configuration principale (inchangée)
└── wsl_test/               # Test WSL isolé (NOUVEAU)
    ├── main.tf             # Configuration Terraform simple
    ├── test_wsl.sh         # Script bash pour WSL
    └── run_from_windows.ps1 # Lancer depuis Windows
```

## 🚀 Options d'exécution

### **Option 1: Depuis WSL directement**
```bash
cd terraform_modules_test/wsl_test
chmod +x test_wsl.sh
./test_wsl.sh
```

### **Option 2: Depuis Windows PowerShell**
```powershell
cd terraform_modules_test\wsl_test
.\run_from_windows.ps1
```

### **Option 3: Manuel WSL**
```bash
cd terraform_modules_test/wsl_test

# 1. Vérifier Airbyte
curl http://localhost:8000/health

# 2. Azure login
az login --use-device-code

# 3. Terraform
export TF_VAR_airbyte_server_url="http://localhost:8000"
terraform init
terraform plan
terraform apply
```

## 🔧 Avantages de cette approche

### ✅ **Isolation complète**
- Pas de conflit avec les autres fichiers `.tf`
- Configuration dédiée WSL
- Tests indépendants

### ✅ **Chemin relatif vers les modules**
```terraform
module "storage" {
  source = "../root/modules/order-test"  # Réutilise les modules existants
}
```

### ✅ **Variables simplifiées**
- Seules les variables nécessaires
- Configuration auto-détectée
- Pas de duplication

### ✅ **Debugging facilité**
- Outputs clairs
- Étapes séquentielles
- Messages d'erreur explicites

## 📋 Ce qui sera créé

### **Infrastructure Azure (via module existant)**
- Resource Group: `ModernDataStack`
- Storage Account: `pimdsdatalake`
- Containers: `foldercsv`, `folderparquet`

### **Configuration Airbyte (directe)**
- Source Faker: 100 records pour test rapide
- Destination ADLS: Vers le container `foldercsv`
- Connection: `WSL Faker to ADLS` (manuel)

## 🔍 Vérification du succès

### **1. Outputs Terraform**
```bash
terraform output
```
Doit afficher toutes les infos de test

### **2. Interface Airbyte**
- URL affichée dans les outputs
- Connection visible et testable
- Sync manuel fonctionnel

### **3. Azure Portal**
```
ModernDataStack → pimdsdatalake → foldercsv → wsl_test/users/
```

## 🧹 Nettoyage

### **Airbyte seulement**
```bash
terraform destroy -target=airbyte_connection.wsl_faker_to_adls
terraform destroy -target=airbyte_destination_azure_blob_storage.wsl_adls  
terraform destroy -target=airbyte_source_faker.wsl_faker
```

### **Tout supprimer**
```bash
terraform destroy
```

## 💡 Résolution des problèmes précédents

| Problème précédent | Solution WSL |
|---|---|
| Conflits de fichiers .tf | ✅ Dossier séparé |
| Providers dupliqués | ✅ Configuration unique |
| depends_on dans modules | ✅ depends_on sur resources |
| Variables dupliquées | ✅ Variables isolées |
| Authentification Azure | ✅ device-code + ARM_USE_CLI |
| Connectivité Airbyte | ✅ Détection auto IP Windows |

## 🎯 Prochaines étapes après succès

1. **Tester d'autres sources** (GCS, bases de données)
2. **Ajouter transformations** (dbt module)
3. **Configurer monitoring** 
4. **Passer en production** avec la config principale

Cette approche vous donne un **environnement de test propre** tout en préservant votre architecture modulaire principale ! 🚀
