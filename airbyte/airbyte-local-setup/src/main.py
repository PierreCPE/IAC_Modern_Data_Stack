# filepath: airbyte-local-setup/src/main.py

import os
from airbyte_api_client import AirbyteApiClient
from airbyte_helper import setup_connection, trigger_sync, check_job_status

def main():
    # Initialize Airbyte client
    client = initialize_airbyte_client(api_url="http://localhost:8000", api_key="")

    # Setup CSV source and ADLS destination
    csv_path = "data/data.csv"
    container_name = "my-container"
    source_id, destination_id = setup_csv_to_adls(client, csv_path, container_name)

    # Create connection
    connection_name = "CSV to ADLS"
    connection = create_connection(client, source_id, destination_id, connection_name)

    # Trigger sync
    job = trigger_sync(client, connection["connectionId"])

    # Check job status
    status = check_job_status(client, job["jobId"])
    print(f"Sync job status: {status}")

if __name__ == "__main__":
    main()