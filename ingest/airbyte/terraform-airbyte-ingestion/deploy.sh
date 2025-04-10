#!/bin/bash
set -e

# Go to the project root directory
cd "$(dirname "$0")"

# 0. Check if docker-compose is running
echo "🔍 Checking if Airbyte and Azurite containers are running..."
if ! docker ps | grep -q azurite; then
    echo "❌ Azurite container is not running. Start the containers first with:"
    echo "   cd ../../../"
    echo "   docker-compose up -d"
    exit 1
fi

# 1. Load environment variables if they exist
if [ -f .env ]; then
    echo "🔑 Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# 2. Check for python and required packages
echo "🔍 Checking for Python and required packages..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python3."
    exit 1
fi

# 3. Install Azure SDK if not already installed
if ! python3 -c "import azure.storage.blob" &> /dev/null; then
    echo "📦 Installing Azure Storage SDK..."
    pip install azure-storage-blob
fi

# 4. Initialize storage container
echo "🚀 Initializing Azure Storage container..."
python3 init_storage.py
if [ $? -ne 0 ]; then
    echo "❌ Failed to initialize Azure Storage container."
    exit 1
fi

# 5. Run terraform
echo "🏗️ Applying Terraform configuration..."
terraform init
terraform apply

echo "✅ Deployment completed successfully!"