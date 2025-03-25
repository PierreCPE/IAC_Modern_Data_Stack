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

def setup_csv_to_adls(client, csv_path, container_name):
    # Create CSV source
    source_config = {
        "name": "Local CSV",
        "sourceDefinitionId": "22f6c74f-5699-40ff-833c-4a879ea40133",  # CSV source ID
        "connectionConfiguration": {
            "url": f"file://{csv_path}",
            "format": "csv"
        }
    }
    source = client.create_source(source_config)

    # Create ADLS destination
    destination_config = {
        "name": "Local ADLS",
        "destinationDefinitionId": "eb2f5c7e-8e3d-4b79-8c3e-6a7e7b3e5a6b",  # ADLS Gen 2 destination ID
        "connectionConfiguration": {
            "storage_account": "devstoreaccount1",
            "container_name": container_name,
            "azure_blob_storage_endpoint": "http://127.0.0.1:10000/devstoreaccount1",
            "azure_blob_storage_sas_token": "?sv=2020-08-04&ss=bfqt&srt=sco&sp=rwdlacupx&se=2030-01-01T00:00:00Z&st=2020-01-01T00:00:00Z&spr=https&sig=..."
        }
    }
    destination = client.create_destination(destination_config)

    return source["sourceId"], destination["destinationId"]