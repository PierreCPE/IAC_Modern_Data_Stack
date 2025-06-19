# Script PowerShell pour lancer le test WSL depuis Windows
Write-Host "🐧 Lancement du test WSL depuis Windows" -ForegroundColor Cyan

# Vérifier WSL
if (!(Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ WSL non installé" -ForegroundColor Red
    exit 1
}

# Vérifier que le dossier existe dans WSL
$wslPath = "/mnt/c/Users/Pierre.Gosson/Documents/Github/Projet_IAC_Modern_Data_Stack_Keyrus/IAC_Modern_Data_Stack/terraform_modules_test/wsl_test"

Write-Host "🔍 Vérification du chemin WSL..." -ForegroundColor Yellow
$pathExists = wsl test -d $wslPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Chemin non trouvé dans WSL: $wslPath" -ForegroundColor Red
    Write-Host "💡 Vérifiez que le dossier existe et que WSL peut y accéder" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Chemin WSL valide" -ForegroundColor Green

# Vérifier Airbyte (optionnel)
Write-Host "🔍 Test Airbyte..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 3 -ErrorAction Stop
    Write-Host "✅ Airbyte accessible sur localhost:8000" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Airbyte non accessible - le script WSL va tenter de le détecter" -ForegroundColor Yellow
}

# Lancer le script dans WSL
Write-Host ""
Write-Host "🚀 Lancement du test dans WSL..." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

# Exécuter dans WSL avec le bon répertoire de travail
wsl --cd $wslPath bash -c "chmod +x test_wsl.sh && ./test_wsl.sh"

Write-Host ""
Write-Host "✅ Test WSL terminé" -ForegroundColor Green
