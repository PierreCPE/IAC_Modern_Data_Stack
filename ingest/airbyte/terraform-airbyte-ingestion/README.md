# Terraform Airbyte Ingestion

This project demonstrates how to automate data ingestion using Airbyte with Terraform. It creates a data pipeline from a Faker source to an Azure Blob Storage destination (using Azurite for local development).
WIP !! : The project also tries to pull from GCS to put in zurite to fit the use case projet tremplin

## Overview

The setup uses:
- **Airbyte**: For ETL pipeline orchestration
- **Azurite**: Local Azure Storage emulator for development
- **Terraform**: Infrastructure as code to provision the pipeline
- **Docker/Kubernetes**: Containers for running the services

## Prerequisites

1. **Docker and Docker Compose**: For running Azurite and other services
2. **Terraform**: Version 1.0.0+
3. **Python 3.7+**: With Azure Storage Blob SDK
4. **Kubectl** (optional): If using Kubernetes for Airbyte

## Quick Start

1. **Start the required containers**:
   ```bash
   cd ../../../
   docker-compose up -d
   ```

2. **Prepare your environment variables**:
   Create a `.env` file with the following variables:
   ```
   # Airbyte credentials
   TF_VAR_client_id="YOUR_CLIENT_ID"
   TF_VAR_client_secret="YOUR_CLIENT_SECRET"
   TF_VAR_workspace_id="YOUR_WORKSPACE_ID"
   
   # Azure Storage settings
   TF_VAR_azure_storage_account_name="devstoreaccount1"
   TF_VAR_azure_container_name="airbytedata"
   TF_VAR_azure_storage_account_key="Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
   ```

3. **Run the deployment script**:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

## Infrastructure Components

### Azure Blob Storage (Azurite)

The project uses Azurite to emulate Azure Blob Storage locally. The container name defaults to `airbytedata`.

### Airbyte Source

We use the Faker source to generate sample data:

```terraform
resource "airbyte_source_faker" "my_source_faker" {
  name         = "My Faker Source"
  workspace_id = var.workspace_id

  configuration = {
    count = 1000
    seed  = 42
  }
}
```

### Airbyte Destination

We configure Azure Blob Storage as a destination:

```terraform
resource "airbyte_destination_custom" "my_adls_destination" {
  name         = "My ADLS Gen2 Destination"
  workspace_id = var.workspace_id

  configuration = <<-EOF
    {
      "destinationType": "azure-blob-storage",
      "azure_blob_storage_account_name": "${var.azure_storage_account_name}",
      "azure_blob_storage_container_name": "${var.azure_container_name}",
      "azure_blob_storage_endpoint_domain_name": "host.docker.internal:10000",
      "azure_blob_storage_account_key": "${var.azure_storage_account_key}",
      "format": {
        "format_type": "CSV", 
        "flattening": "No flattening",
        "compression": {
          "compression_type": "No compression"
        }
      }
    }
  EOF
}
```

### Airbyte Connection

This connects the source to the destination:

```terraform
resource "airbyte_connection" "faker_to_adls" {
  name           = "Faker to ADLS Gen2"
  source_id      = airbyte_source_faker.my_source_faker.source_id
  destination_id = airbyte_destination_custom.my_adls_destination.destination_id

  namespace_definition = "source"
  namespace_format     = "${airbyte_source_faker.my_source_faker.name}_${airbyte_destination_custom.my_adls_destination.name}"

  schedule = {
    schedule_type = "manual"
  }
}
```

## Adding New Connectors

### Sources

To add a new source:

1. Find the appropriate Terraform resource for your source in the [Airbyte Terraform Provider documentation](https://registry.terraform.io/providers/airbytehq/airbyte/latest/docs).

2. Add the resource to your Terraform configuration:
   ```terraform
   resource "airbyte_source_[type]" "my_source" {
     name         = "My Source"
     workspace_id = var.workspace_id

     configuration = {
       // Source-specific configuration
     }
   }
   ```

### Destinations

To add a new destination:

1. Ensure the connector is installed in your Airbyte instance
2. For custom destinations, use the `airbyte_destination_custom` resource:
   ```terraform
   resource "airbyte_destination_custom" "my_destination" {
     name         = "My Destination"
     workspace_id = var.workspace_id

     configuration = <<-EOF
       {
         "destinationType": "destination-type-name",
         // Destination-specific configuration
       }
     EOF
   }
   ```

## Troubleshooting

### Connector Not Found

If you see an error like `{"value":"azure_blob_storage"}} could not be found`:

1. Check if the connector is installed in Airbyte
2. Install it through the deployment script or manually:
   ```bash
   docker exec <airbyte-container> bash -c 'airbyte-cli install destination-azure-blob-storage'
   ```
   or
   ```bash
   kubectl exec -it <airbyte-pod> -- bash -c 'airbyte-cli install destination-azure-blob-storage'
   ```

### Networking Issues

If Airbyte can't connect to Azurite:

1. For Docker: Use `host.docker.internal:10000` instead of `localhost:10000`
2. For Kubernetes: Use the service name or pod IP address

### Schema Validation Errors

If you see schema validation errors, check:

1. The destination type name is correct
2. Field names match what the connector expects
3. The format configuration is correct

## Project Structure

- **deploy.sh**: Deployment script that initializes storage and applies Terraform
- **init_storage.py**: Python script to initialize the Azure Blob Storage container
- **main.tf**: Main Terraform configuration file
- **variables.tf**: Variable definitions
- **.env**: Environment variables (not tracked in Git)

## References

- [Airbyte Documentation](https://docs.airbyte.com/)
- [Airbyte Terraform Provider](https://registry.terraform.io/providers/airbytehq/airbyte/latest/docs)
- [Azure Blob Storage Connector](https://docs.airbyte.com/integrations/destinations/azure-blob-storage)
