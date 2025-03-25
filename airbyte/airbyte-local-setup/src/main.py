import airbyte_lib as ab
import os
from datetime import datetime
from utils.airbyte_helper import setup_csv_to_adls  # Importer la fonction pour uploader vers ADLS
import matplotlib.pyplot as plt
import pandas as pd

def main():
    # Initialize Airbyte connexion basic exemple
    source: ab.Source = ab.get_source(
        "source-faker",
        config={
            "count": 50_000,
            "seed": 123,
        }
    )

    source.select_all_streams()
    read_results: ab.ReadResult = source.read()
    print(read_results)

    # Extraire les données des streams
    users_df = read_results.streams["users"].to_pandas()
    

    # Convertir les types non reconnus en types standards
    users_df = users_df.astype({
        "id": "int64",
        "age": "int64",
        "weight": "int64",
        "name": "string",
        "title": "string",
        "email": "string",
        "telephone": "string",
        "gender": "string",
        "language": "string",
        "academic_degree": "string",
        "nationality": "string",
        "occupation": "string",
        "height": "string",
        "blood_type": "string",
        "address": "string"
    })

    print(users_df.head())
    # Convertir les données en Parquet
    output_dir = "data"
    os.makedirs(output_dir, exist_ok=True)

    # Générer un nom de fichier avec un timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    parquet_filename = f"users_{timestamp}.parquet"
    parquet_filepath = os.path.join(output_dir, parquet_filename)

    # Sauvegarder les données en Parquet
    users_df.to_parquet(parquet_filepath, index=False)
    print(f"Data saved as Parquet to {parquet_filepath}")

    try:
        df = pd.read_parquet(parquet_filepath)
        print(df.head())
    except Exception as e:
        print(f"Erreur de lecture du fichier Parquet : {e}")

    # Uploader le fichier Parquet dans ADLS (Azurite)
    container_name = "my-container"
    try:
        setup_csv_to_adls(None, parquet_filepath, container_name)  # Uploader le fichier vers ADLS
        print(f"Uploaded {parquet_filename} to ADLS container '{container_name}'")
    except Exception as e:
        print(f"Error uploading {parquet_filename} to ADLS: {e}")

if __name__ == "__main__":
    main()