# Airbyte Local Setup

This directory contains the setup for running Airbyte locally, along with a pipeline to convert a CSV file to Parquet format using PySpark and upload it to an Azure Data Lake Storage Gen 2 (emulated locally with Azurite).

## Prerequisites

1. **Docker**: Ensure Docker is installed and running.
2. **Python**: Install Python 3.10.
3. **Java**: Install Java (required for PySpark).

   ```bash
   sudo apt update
   sudo apt install default-jre -y
   ```

4. **Virtual Environment**: Create and activate a virtual environment.

   ```bash
   python3.10 -m venv .venv
   source .venv/bin/activate
   ```

5. **Install Dependencies**: Install the required Python packages.

   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

## Steps to Run the Pipeline Locally

1. **Start Azurite (ADLS Gen 2 Emulator)**

   Use Docker Compose to start Azurite:

   ```bash
   docker-compose up -d azurite
   ```

   Azurite will be available at `http://127.0.0.1:10000`.

2. **Prepare the Input CSV or Use the mock data from the airbyte librairy**

   Place your input CSV file in the `data/` directory. For example, `data/data.csv`.

3. **Run the Pipeline**

   Execute the `main.py` script to convert the CSV to Parquet and upload it to Azurite:

   ```bash
   python src/main.py
   ```

4. **Verify the Upload**

   Use Azure Storage Explorer or the Azurite logs to verify that the Parquet file has been uploaded to the container `my-container`.
   I also wrote a script to see the list of my blobs inside the ADLS
   You can run : 

   ```bash
   python src/list_blobs.py
   ```



## Notes

- This project uses the `airbyte` library to fetch data from sources. The library automatically installs and configures the required sources. To fetch data, simply configure the source in `main.py` and run the script:
- The pipeline uses PySpark for data processing and Azure Storage Blob SDK for uploading files to Azurite.
- Ensure that the `data/` directory exists and contains the input CSV file before running the script.
- You can modify the container name or file paths in `src/main.py` as needed.

## Troubleshooting

### Problème : "The virtual environment was not created successfully because ensurepip is not available"

Si vous rencontrez cette erreur, cela signifie que le module ensurepip n'est pas disponible dans votre installation Python. Voici comment résoudre ce problème :

1. **Installez le package python3-venv**:

   ```bash
   sudo apt install python3.12-venv
   ```

2. **Recréez l'environnement virtuel**:

```bash
rm -rf .venv
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

3. **Relancez le script**:

```bash
python src/main.py
```

### Problème : "(.venv) (.venv)" dans le terminal

Cela se produit lorsque vous activez plusieurs fois l'environnement virtuel. Pour résoudre ce problème :

1. **Désactivez l'environnement virtuel en cours**:

```bash
deactivate
```

2. **Réactivez-le une seule fois**:

```bash
source .venv/bin/activate
```

- **Azurite Issues**: Ensure that the Docker container is running and accessible at `http://127.0.0.1:10000`.
- **PySpark Errors**: Ensure that Java is installed and properly configured on your system.
- **Missing Dependencies**: Ensure you have installed all required dependencies using the `requirements.txt`.