# Airbyte Modern Data Stack on Azure VM

This project provides **Infrastructure as Code** to deploy a complete Airbyte-based modern data stack on an Azure Virtual Machine. It uses Terraform, cloud-init, and automation scripts to set up all dependencies, run Airbyte (via `abctl`), and configure a local Azure Blob Storage emulator (Azurite) for development and testing.

---

## Project Structure

To be seen in the plain md for better rendition.

azure_vm_setup/ 
    ├── main.tf  # Terraform config for Azure VM and resources 
    ├── terraform.tfvars # Your secrets/variables (NOT in git) 
    ├── cloud-init.yaml # Cloud-init for VM provisioning and Airbyte setup 
    └── .terraform/ # Terraform local state and providers (ignored in git) 

ingest/airbyte/terraform-airbyte-ingestion/ 
                                    ├── main.tf # Airbyte Terraform pipeline config 
                                    ├── variables.tf # Variables for Airbyte pipeline 
                                    ├── deploy.sh # Script to run Airbyte pipeline 
                                    └── ... # Other Airbyte pipeline files


## How It Works

### 1. **Terraform Provisions the Azure VM**

- `main.tf` defines an Ubuntu VM, network, security group, and attaches a `cloud-init.yaml` for first-boot provisioning.
- The VM is created with **password authentication** (see below for security).

### 2. **Cloud-init Bootstraps the VM**
What it does : 

- Installs Docker, Docker Compose, kubectl, Terraform, Python, Git, jq, and the Airbyte CLI (`abctl`).
- Clones your Airbyte project repo into `/home/azureuser/airbyte-deployment/IAC_Modern_Data_Stack`.
- Installs Airbyte using `abctl local install --low-resource-mode` (runs Airbyte in Docker).
- Starts Azurite (Azure Blob Storage emulator) in Docker.
- Sets up a Python virtual environment and installs `azure-storage-blob`.
- Creates a `deploy.sh` script for further Airbyte pipeline automation.

### 3. **Airbyte Pipeline Automation**

What it does : 

- The generated `deploy.sh` script:
  - Retrieves Airbyte API credentials using `abctl local credentials`.
  - Extracts the workspace ID via Airbyte's API.
  - Sets up a `.env` file with all required variables for the Airbyte Terraform provider and Azurite.
  - Runs `terraform init` and `terraform apply` in the Airbyte ingestion directory to provision sources, destinations, and connections.

---

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated (`az login`)
- [Terraform](https://www.terraform.io/downloads.html) installed locally
- An Azure subscription

---

## Setup & Usage

### 1. **Clone This Repository**

```bash
git clone https://github.com/PierreCPE/IAC_Modern_Data_Stack.git
cd IAC_Modern_Data_Stack/azure_vm_setup         
```

### 2. **Configure Your VM Password**

Create a `terraform.tfvars` file (never commit this to git)

```bash
vm_password = "YourStrongPasswordHere!"       
```

> Note: The VM will use this password for the azureuser account.

### 3. **Deploy the Azure VM**

```bash
terraform init
terraform apply       
```

* Confirm the apply when prompted.
* After a few minutes, Terraform will output the VM's public IP address.

### 4. **Access the VM**


```bash
ssh azureuser@<public_ip_address>
# Use the password you set in terraform.tfvars    
```

### 5. **(Optional) Run the Airbyte Pipeline Script**

```bash
cd ~/airbyte-deployment
bash deploy.sh    
```

## **Accessing Airbyte**

* Once deployment is complete, open your browser to: `http://<public_ip_address>:8000`

* Log in using the credentials output by `abctl local credentials` (also saved in `~/airbyte-credentials.txt` on the VM).

## **Security Notes**

* **Never commit `terraform.tfvars` or any file with secrets to git.**

* The `terraform/`directory and all state files are ignored in `.gitignore`

* For production, consider using SSH keys instead of password authentication.

## **Customization**

* To change the Airbyte pipeline (sources, destinations, connections), edit files in ingest/airbyte/`terraform-airbyte-ingestion/` and re-run `deploy.sh` on the VM.

* To use a different repo, update the `git clone` command in `cloud-init.yaml`.

## **Troubleshooting**

* If you see errors about large files when pushing to git, ensure `.terraform/` and `.tfstate` files are in .`gitignore`.

* If Airbyte is not accessible, check Docker containers (`docker ps`) and logs (`docker logs <container>`).

* If you need to reset, you can destroy the VM with `terraform destroy` and re-apply.

## References

- [Airbyte Documentation](https://docs.airbyte.com/)
- [abctl CLI](https://docs.airbyte.com/deploying-airbyte/abctl/)
- [Azurite Emulator](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)


