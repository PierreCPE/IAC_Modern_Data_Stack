# 🐧 Guide de Dépannage WSL - Airbyte + Azure

## 🚀 Utilisation

```bash
# Rendre le script exécutable
chmod +x test_wsl.sh

# Exécuter le test
./test_wsl.sh
```

## 🔧 Problèmes courants et solutions

### ❌ **Problème 1: Airbyte non accessible depuis WSL**

**Symptôme:**
```
❌ Airbyte non accessible depuis WSL
```

**Solutions:**

#### **Option A: Démarrer Airbyte dans WSL**
```bash
# Dans WSL
git clone https://github.com/airbytehq/airbyte.git
cd airbyte
./run-ab-platform.sh
```

#### **Option B: Port forwarding Windows → WSL**
```powershell
# Dans PowerShell Admin (Windows)
netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=127.0.0.1

# Vérifier
netsh interface portproxy show all
```

#### **Option C: Trouver l'IP Windows**
```bash
# Dans WSL
ip route show | grep -i default
# Ou
cat /etc/resolv.conf | grep nameserver
```

---

### ❌ **Problème 2: Authentification Azure échoue**

**Symptôme:**
```
❌ Non connecté à Azure
```

**Solutions:**

#### **Device Code Login (Recommandé pour WSL)**
```bash
az login --use-device-code
```
- Copier le code affiché
- Ouvrir https://microsoft.com/devicelogin dans Windows
- Entrer le code

#### **Vérifier l'authentification**
```bash
az account show
az account list --output table
```

#### **Changer de subscription si nécessaire**
```bash
az account set --subscription "nom-ou-id-subscription"
```

---

### ❌ **Problème 3: Terraform provider Azure errors**

**Symptôme:**
```
Error: building AzureRM Client: could not configure credential
```

**Solutions:**

#### **Forcer l'authentification CLI**
```bash
export ARM_USE_CLI=true
export ARM_SKIP_PROVIDER_REGISTRATION=true
```

#### **Vérifier les permissions**
```bash
# Lister les rôles
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Permissions minimales requises:
# - Contributor ou Owner sur la subscription
# - Ou Storage Account Contributor + Resource Group Contributor
```

---

### ❌ **Problème 4: Erreurs de ressources Azure**

**Symptôme:**
```
Error: creating Storage Account: resources.AccountsClient#Create
```

**Solutions:**

#### **Vérifier les quotas**
```bash
az vm list-usage --location francecentral --output table
```

#### **Tester avec une région différente**
```bash
# Modifier dans le module azure-datalake/main.tf
location = "westeurope"  # au lieu de "francecentral"
```

#### **Nom du storage account unique**
Le nom doit être globalement unique (3-24 caractères, lettres/chiffres uniquement)

---

### ❌ **Problème 5: Airbyte provider errors**

**Symptôme:**
```
Error: error creating source: could not create source
```

**Solutions:**

#### **Vérifier la connectivité Airbyte**
```bash
# Test manuel
curl -X GET "http://localhost:8000/api/v1/workspaces/list" \
  -H "Authorization: Bearer $(echo -n 'airbyte:password' | base64)"
```

#### **Workspace ID incorrect**
```bash
# Récupérer le bon workspace ID
curl -s "http://localhost:8000/api/v1/workspaces/list" | jq '.workspaces[0].workspaceId'
```

#### **Attendre qu'Airbyte soit complètement démarré**
```bash
# Vérifier tous les services
docker ps | grep airbyte
```

---

## 🔍 Debug étape par étape

### **1. Test de connectivité réseau**
```bash
# Test Airbyte
curl -s http://localhost:8000/health
curl -s http://$(ip route show | grep -i default | awk '{ print $3}'):8000/health

# Test Azure
az account show
```

### **2. Test Terraform basique**
```bash
# Validation seulement
terraform init
terraform validate
terraform plan -target=module.order-test
```

### **3. Déploiement par étapes**
```bash
# 1. Infrastructure seulement
terraform apply -target=module.order-test

# 2. Source Airbyte seulement
terraform apply -target=airbyte_source_faker.test_faker

# 3. Destination Airbyte
terraform apply -target=airbyte_destination_azure_blob_storage.test_adls

# 4. Connexion finale
terraform apply -target=airbyte_connection.faker_to_adls_test
```

### **4. Test manuel dans Airbyte UI**
1. Ouvrir http://localhost:8000
2. Sources → Vérifier "WSL Test Faker"
3. Destinations → Vérifier "WSL Test ADLS Destination"
4. Connections → "WSL Faker to ADLS Test" → Test connection
5. Sync now

---

## 📱 Vérification du succès

### **Azure Portal**
- Resource Group: `ModernDataStack`
- Storage Account: `pimdsdatalake`
- Container: `foldercsv`
- Fichiers: `wsl_test/users/...`

### **CLI Azure**
```bash
az storage blob list --account-name pimdsdatalake --container-name foldercsv --output table
```

### **Logs Airbyte**
- UI → Connections → WSL Faker to ADLS Test → History
- Vérifier les logs de sync

---

## 🧹 Nettoyage

```bash
# Supprimer les ressources Airbyte
terraform destroy -target=airbyte_connection.faker_to_adls_test
terraform destroy -target=airbyte_destination_azure_blob_storage.test_adls
terraform destroy -target=airbyte_source_faker.test_faker

# Supprimer l'infrastructure Azure
terraform destroy -target=module.order-test

# Nettoyage complet
terraform destroy
```

---

## 💡 Tips WSL

- **Utiliser device code login** pour Azure
- **Démarrer Airbyte dans WSL** pour éviter les problèmes réseau
- **Variables d'environnement** persistent dans la session bash
- **Ports forwarding** peut être nécessaire selon la configuration WSL
