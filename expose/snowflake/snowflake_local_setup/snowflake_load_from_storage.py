from azure.storage.blob import BlobServiceClient
import pandas as pd
import snowflake.connector

def load_parquet_to_snowflake(container_name, blob_name, connection_string, snowflake_conn):
    # Connect to ADLS
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)

    # Télécharger le fichier Parquet
    blob_client = container_client.get_blob_client(blob_name)
    with open("temp.parquet", "wb") as f:
        f.write(blob_client.download_blob().readall())

    # Lire le fichier Parquet avec Pandas
    df = pd.read_parquet("temp.parquet")

    # Charger les données dans Snowflake
    cursor = snowflake_conn.cursor()
    for _, row in df.iterrows():
        cursor.execute(
            """
            INSERT INTO users (id, age, weight, name, title, email, telephone, gender, language, academic_degree, nationality, occupation, height, blood_type, address)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            tuple(row)
        )
    cursor.close()
    print("Data loaded into Snowflake successfully!")

# Exemple d'utilisation
connection_string = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFeq...;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
snowflake_conn = snowflake.connector.connect(
    user="YOUR_USER",
    password="YOUR_PASSWORD",
    account="YOUR_ACCOUNT"
)
load_parquet_to_snowflake("my-container", "users_20250325_131500.parquet", connection_string, snowflake_conn)