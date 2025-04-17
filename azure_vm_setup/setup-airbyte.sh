#!/bin/bash


set -e

# Update package lists
apt-get update

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Start & enable Docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
apt-get install -y docker-compose-plugin
ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Add user to docker group
usermod -aG docker azureuser

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Terraform
apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform

# Install Python and pip
apt-get install -y python3-pip python3-venv git jq

# Install abctl - Airbyte's command-line tool
curl -LsfS https://get.airbyte.com | bash -

# Create deployment directory
mkdir -p /home/azureuser/airbyte-deployment
chown -R azureuser:azureuser /home/azureuser/airbyte-deployment

# Create deployment script for azureuser
cat > /home/azureuser/airbyte-deployment/deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting Airbyte deployment..."

# Clone the repository
if [ ! -d "/home/azureuser/airbyte-deployment/IAC_Modern_Data_Stack" ]; then
  echo "Cloning repository..."
  git clone https://github.com/PierreCPE/IAC_Modern_Data_Stack.git /home/azureuser/airbyte-deployment/IAC_Modern_Data_Stack
fi

# Install Airbyte with abctl
echo "Installing Airbyte with abctl..."
abctl local install --low-resource-mode

# Wait for Airbyte to be ready
echo "Waiting for Airbyte to be ready..."
until curl -s http://localhost:8000 > /dev/null; do
  echo "Waiting for Airbyte to start..."
  sleep 10
done
echo "Airbyte is up and running!"

# Get Airbyte credentials
echo "Getting Airbyte credentials..."
CREDENTIALS=$(abctl local credentials)
echo "$CREDENTIALS" > /home/azureuser/airbyte-credentials.txt
echo "Credentials saved to ~/airbyte-credentials.txt"

# Extract client ID and secret
CLIENT_ID=$(echo "$CREDENTIALS" | grep "Client-Id:" | awk '{print $2}')
CLIENT_SECRET=$(echo "$CREDENTIALS" | grep "Client-Secret:" | awk '{print $2}')
echo "Client ID: $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"

# Get workspace ID
echo "Getting workspace ID..."
WORKSPACE_ID=$(curl -s -X GET "http://localhost:8000/api/public/v1/workspaces" \
  -H "Authorization: Basic $(echo -n ${CLIENT_ID}:${CLIENT_SECRET} | base64)" \
  | jq -r '.data[0].workspaceId')
echo "Workspace ID: $WORKSPACE_ID"

# Start Azurite container
echo "Starting Azurite container..."
docker run -d --name azurite -p 10000:10000 -p 10001:10001 -p 10002:10002 mcr.microsoft.com/azure-storage/azurite

# Navigate to the Terraform Airbyte ingestion directory
cd /home/azureuser/airbyte-deployment/IAC_Modern_Data_Stack/IAC_Modern_Data_Stack/ingest/airbyte/terraform-airbyte-ingestion

# Create Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
pip install azure-storage-blob

# Create .env file with credentials
cat > .env << EOL
# Airbyte credentials
TF_VAR_client_id="${CLIENT_ID}"
TF_VAR_client_secret="${CLIENT_SECRET}"
TF_VAR_workspace_id="${WORKSPACE_ID}"

# Azure Storage settings
TF_VAR_azure_storage_account_name="devstoreaccount1"
TF_VAR_azure_container_name="airbytedata"
TF_VAR_azure_storage_account_key="Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
EOL

# Run deployment script
echo "Running Airbyte Terraform deployment script..."
chmod +x deploy.sh
./deploy.sh

echo "Deployment complete! Airbyte is running at http://localhost:8000"
EOF

# Make script executable
chmod +x /home/azureuser/airbyte-deployment/deploy.sh
chown azureuser:azureuser /home/azureuser/airbyte-deployment/deploy.sh

echo "Setup complete! Log in as azureuser and run ~/airbyte-deployment/deploy.sh to complete the installation."