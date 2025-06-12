## Project Overview

This project is designed to deploy an Azure Function that converts CSV files to Parquet format. It utilizes Terraform for infrastructure as code (IaC) to provision the necessary Azure resources.

## Project Structure

```
terraform_azure_function/
├── function/                 # Code de l'Azure Function
│   └── csv_to_parquet/
│       ├── __init__.py       # Logique de conversion CSV → Parquet
│       ├── function.json     # Configuration du déclencheur
│       └── requirements.txt  # Dépendances Python
├── scripts/
│   └── local_processing.py   # Script pour tests locaux
├── terraform/                # Infrastructure as Code
│   ├── main.tf              # Définition des ressources Azure
│   ├── variables.tf         # Paramètres configurables
│   └── outputs.tf           # Informations après déploiement
└── README.md
```

## Usage Instructions

1. **Set Up Terraform**: Ensure you have Terraform installed on your machine. Configure your Azure credentials to allow Terraform to create resources in your Azure account.

2. **Configure Variables**: Edit the `variables.tf` file to set your desired values for the resource group name, location, storage account name, and function app name.

3. **Deploy Infrastructure**:
   - Navigate to the `terraform` directory.
   - Run `terraform init` to initialize the Terraform configuration.
   - Run `terraform apply` to create the resources defined in the configuration files.

4. **Deploy the Azure Function**:
   - Navigate to the `function/csv_to_parquet` directory.
   - Install the required Python packages listed in `requirements.txt` using `pip install -r requirements.txt`.
   - Deploy the function to Azure using the Azure CLI or through the Azure portal.

5. **Run Local Processing**: If you want to test the data processing locally, you can run the `local_processing.py` script.
