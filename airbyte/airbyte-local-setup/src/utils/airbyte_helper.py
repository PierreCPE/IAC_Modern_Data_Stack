from azure.storage.blob import BlobServiceClient

def initialize_airbyte_client(api_url: str, api_key: str):
    from airbyte_api_client import AirbyteApiClient

    client = AirbyteApiClient(api_url=api_url, api_key=api_key)
    return client

def create_connection(client, source_id: str, destination_id: str, connection_name: str):
    connection_config = {
        "sourceId": source_id,
        "destinationId": destination_id,
        "name": connection_name,
        "syncMode": "full_refresh",
        "schedule": {
            "units": "hours",
            "interval": 1
        }
    }
    response = client.create_connection(connection_config)
    return response

def trigger_sync(client, connection_id: str):
    response = client.trigger_sync(connection_id)
    return response

def check_job_status(client, job_id: str):
    status = client.get_job_status(job_id)
    return status

def setup_csv_to_adls(client, parquet_path, container_name):
    """Upload a Parquet file to ADLS Gen 2 (Azurite)."""
    # Connection string for Azurite
    connection_string = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFeq..." \
                        "azurite-key...;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"

    # Initialize BlobServiceClient
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

    # Create container if it doesn't exist
    container_client = blob_service_client.get_container_client(container_name)
    if not container_client.exists():
        container_client.create_container()
        print(f"Created container: {container_name}")

    # Upload Parquet file
    blob_name = os.path.basename(parquet_path)
    blob_client = container_client.get_blob_client(blob_name)

    with open(parquet_path, "rb") as data:
        blob_client.upload_blob(data, overwrite=True)
        print(f"Uploaded {parquet_path} to container {container_name} as {blob_name}")