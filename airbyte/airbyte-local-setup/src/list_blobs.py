from azure.storage.blob import BlobServiceClient

def list_blobs_in_container(container_name):
    connection_string = ()
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)

    print(f"Blobs in container '{container_name}':")
    for blob in container_client.list_blobs():
        print(f"- {blob.name}")

if __name__ == "__main__":
    list_blobs_in_container("my-container")