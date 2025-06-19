# Test Faker → ADLS avec Airbyte OSS
Write-Host "🧪 Test Faker → ADLS avec Airbyte OSS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Vérifications préalables
Write-Host "🔍 Vérification des prérequis..." -ForegroundColor Yellow

# 1. Vérifier Airbyte OSS
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Airbyte OSS accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ Airbyte OSS n'est pas accessible" -ForegroundColor Red
    Write-Host ""
    Write-Host "📋 Pour démarrer Airbyte OSS :" -ForegroundColor Yellow
    Write-Host "   git clone https://github.com/airbytehq/airbyte.git"
    Write-Host "   cd airbyte"
    Write-Host "   .\run-ab-platform.bat"
    Write-Host ""
    Write-Host "   Puis attendez que http://localhost:8000 soit accessible"
    exit 1
}

# 2. Vérifier Azure CLI
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI non installé" -ForegroundColor Red
    Write-Host "   Installez depuis: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows"
    exit 1
}

try {
    az account show --output none
    Write-Host "✅ Azure CLI configuré" -ForegroundColor Green
} catch {
    Write-Host "🔑 Connexion à Azure requise..." -ForegroundColor Yellow
    az login
}

# 3. Vérifier Terraform
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Terraform non installé" -ForegroundColor Red
    exit 1
}

# 4. Initialiser Terraform
Write-Host "🏗️ Initialisation Terraform..." -ForegroundColor Yellow
if (!(Test-Path ".terraform")) {
    terraform init
} else {
    Write-Host "   Terraform déjà initialisé" -ForegroundColor Gray
}

# 5. Planifier le déploiement
Write-Host "📋 Planification du déploiement..." -ForegroundColor Yellow
terraform plan -target=module.order-test -target=airbyte_source_faker.test_faker -target=airbyte_destination_azure_blob_storage.test_adls -target=airbyte_connection.faker_to_adls_test

# 6. Demander confirmation
Write-Host ""
$confirmation = Read-Host "🚀 Voulez-vous déployer ? (y/N)"
if ($confirmation -notmatch "^[Yy]$") {
    Write-Host "❌ Déploiement annulé" -ForegroundColor Red
    exit 0
}

# 7. Déployer
Write-Host "🚀 Déploiement en cours..." -ForegroundColor Green
terraform apply -target=module.order-test -target=airbyte_source_faker.test_faker -target=airbyte_destination_azure_blob_storage.test_adls -target=airbyte_connection.faker_to_adls_test -auto-approve

# 8. Récupérer les outputs
Write-Host ""
Write-Host "✅ Déploiement terminé !" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Informations de déploiement :" -ForegroundColor Cyan
terraform output

Write-Host ""
Write-Host "🎯 Prochaines étapes pour tester :" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 🌐 Ouvrir l'interface Airbyte :"
Write-Host "   http://localhost:8000" -ForegroundColor Blue
Write-Host "   Login: airbyte / password"
Write-Host ""
Write-Host "2. 🔄 Dans Airbyte, aller dans 'Connections'"
Write-Host "   Trouver 'Faker to ADLS Test'"
Write-Host "   Cliquer sur 'Sync now' pour déclencher manuellement"
Write-Host ""
Write-Host "3. 📁 Vérifier les données dans Azure :"
Write-Host "   Resource Group: ModernDataStack"
try {
    $storageAccount = terraform output -raw storage_account_name
    Write-Host "   Storage Account: $storageAccount"
} catch {
    Write-Host "   Storage Account: pimdsdatalake"
}
Write-Host "   Container: foldercsv"
Write-Host ""
Write-Host "4. 📈 Surveiller le progress :"
Write-Host "   Les logs du sync seront visibles dans l'UI Airbyte"
Write-Host ""
Write-Host "💡 Tip: La première sync peut prendre quelques minutes" -ForegroundColor Yellow

# Ouvrir automatiquement Airbyte
Write-Host ""
$openBrowser = Read-Host "🌐 Ouvrir Airbyte dans le navigateur ? (y/N)"
if ($openBrowser -match "^[Yy]$") {
    Start-Process "http://localhost:8000"
}
