from azure.storage.blob import BlobServiceClient

# Connexion à Azurite
connection_string = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
blob_service_client = BlobServiceClient.from_connection_string(connection_string)

# Lister tous les conteneurs
containers = blob_service_client.list_containers()
print("Conteneurs:")
for container in containers:
    print(f" - {container.name}")
    
    # Lister les blobs dans ce conteneur
    container_client = blob_service_client.get_container_client(container.name)
    print("   Fichiers:")
    for blob in container_client.list_blobs():
        print(f"    * {blob.name} ({blob.size/1024/1024:.2f} MB)")