# 🧪 Guide de Test : Faker → ADLS avec Airbyte

## 🚀 Démarrage rapide

### **Étape 1 : Démarrer Airbyte OSS**
```bash
# Cloner et démarrer Airbyte (si pas déjà fait)
git clone https://github.com/airbytehq/airbyte.git
cd airbyte
./run-ab-platform.sh    # Linux/Mac
# OU
.\run-ab-platform.bat   # Windows
```

Attendez que Airbyte soit accessible sur http://localhost:8000

### **Étape 2 : Exécuter le test**

#### **Option A : Script automatisé (Windows)**
```powershell
cd terraform_modules_test/root
.\test_faker.ps1
```

#### **Option B : Script automatisé (Linux/Mac)**
```bash
cd terraform_modules_test/root
chmod +x test_faker.sh
./test_faker.sh
```

#### **Option C : Manuel**
```bash
# Connexion Azure
az login

# Terraform
terraform init
terraform apply -target=module.order-test -target=airbyte_source_faker.test_faker -target=airbyte_destination_azure_blob_storage.test_adls -target=airbyte_connection.faker_to_adls_test
```

## 🎯 Ce qui sera créé

### **Infrastructure Azure**
- ✅ Resource Group : `ModernDataStack`
- ✅ Storage Account : `pimdsdatalake` (ADLS Gen2)
- ✅ Container : `foldercsv`

### **Configuration Airbyte**
- ✅ Source Faker : Génère 1000 records (users, products, purchases)
- ✅ Destination ADLS : Export vers votre storage account
- ✅ Connexion : Pipeline Faker → ADLS (mode manuel)

## 🔄 Tester l'ingestion

### **1. Interface Airbyte**
1. Ouvrir http://localhost:8000
2. Login : `airbyte` / `password`
3. Aller dans **Connections** → **Faker to ADLS Test**
4. Cliquer sur **"Sync now"**

### **2. Vérifier les données**
1. **Azure Portal** : portal.azure.com
2. **Resource Group** : ModernDataStack
3. **Storage Account** : pimdsdatalake
4. **Container** : foldercsv
5. **Fichiers** : Vous devriez voir des fichiers CSV créés

### **3. Surveiller le progrès**
- Les logs sont visibles dans l'UI Airbyte
- La première sync prend généralement 1-3 minutes

## 📊 Structure des données générées

### **Streams Faker créés :**
- **users** : Utilisateurs fictifs avec id, nom, email, etc.
- **products** : Produits fictifs avec id, nom, prix, etc.
- **purchases** : Achats fictifs reliant users et products

### **Format de sortie :**
```
foldercsv/
├── faker_test/
│   ├── users/
│   │   └── users_data.csv
│   ├── products/
│   │   └── products_data.csv
│   └── purchases/
│       └── purchases_data.csv
```

## 🛠️ Dépannage

### **❌ Airbyte non accessible**
```bash
# Vérifier le statut
docker ps | grep airbyte

# Redémarrer si nécessaire
cd airbyte
docker-compose down
./run-ab-platform.sh
```

### **❌ Erreur Azure connection**
```bash
# Re-login Azure
az logout
az login

# Vérifier les permissions
az account list --output table
```

### **❌ Sync échoue dans Airbyte**
1. Vérifier les credentials de destination dans l'UI
2. Tester la connection manuellement
3. Consulter les logs détaillés

## 🎉 Résultat attendu

Si tout fonctionne :
- ✅ Infrastructure Azure déployée
- ✅ Source et destination Airbyte configurées
- ✅ Sync manuel réussi
- ✅ Fichiers CSV dans le container ADLS

## 🔄 Nettoyage (optionnel)

```bash
# Supprimer les ressources de test
terraform destroy -target=airbyte_connection.faker_to_adls_test -target=airbyte_destination_azure_blob_storage.test_adls -target=airbyte_source_faker.test_faker

# Supprimer l'infrastructure Azure (attention !)
terraform destroy
```
