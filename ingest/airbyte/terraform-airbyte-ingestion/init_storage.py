from azure.storage.blob import BlobServiceClient
import os
import sys

def create_container():
    # Read from environment variables or use defaults for local Azurite
    account_name = os.environ.get('AZURE_STORAGE_ACCOUNT', 'devstoreaccount1')
    container_name = os.environ.get('AZURE_CONTAINER_NAME', 'airbytedata')
    
    # For Azurite local emulator
    conn_str = f"DefaultEndpointsProtocol=http;AccountName={account_name};AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://localhost:10000/{account_name};"
    
    try:
        # Create the BlobServiceClient
        blob_service_client = BlobServiceClient.from_connection_string(conn_str)
        
        # Get the container client
        container_client = blob_service_client.get_container_client(container_name)
        
        # Create the container if it doesn't exist
        if not container_client.exists():
            container_client.create_container()
            print(f"✅ Container '{container_name}' created successfully")
        else:
            print(f"✅ Container '{container_name}' already exists")
            
        return True
    except Exception as e:
        print(f"❌ Error creating container: {str(e)}")
        return False

if __name__ == "__main__":
    success = create_container()
    if not success:
        sys.exit(1)