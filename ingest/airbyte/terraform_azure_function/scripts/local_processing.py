import pandas as pd
import os
import glob
import argparse
from azure.storage.filedatalake import DataLakeServiceClient
from tqdm import tqdm
import time
import multiprocessing
import base64

def convert_csv_to_parquet(csv_file, output_dir, chunk_size=100000):
    """Convert a CSV file to Parquet format"""
    base_name = os.path.basename(csv_file)
    file_name = os.path.splitext(base_name)[0]
    output_file = os.path.join(output_dir, f"{file_name}.parquet")
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Converting {base_name} to Parquet...")
    
    # Process the file in chunks to handle large files
    for i, chunk in enumerate(tqdm(pd.read_csv(csv_file, chunksize=chunk_size))):
        for col in chunk.select_dtypes(include=['object']).columns:
            if chunk[col].str.len().max() < 50:  # Colonnes avec des chaînes courtes
                chunk[col] = chunk[col].astype('category')
                
        append = i > 0
        chunk.to_parquet(
            output_file,
            engine='fastparquet',
            compression='snappy',
            index=False,
            append=append
        )
    
    print(f"Conversion complete: {output_file}")
    return output_file

def upload_to_adls(file_path, connection_string, container_name):
    """Upload a file to Azure Storage (compatible with Azurite)"""
    from azure.storage.blob import BlobServiceClient
    
    file_name = os.path.basename(file_path)
    file_size = os.path.getsize(file_path)
    
    print(f"Uploading {file_name} ({file_size/1024/1024:.1f} MB) to {container_name} container...")
    
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)
    
    # Ensure container exists
    try:
        container_client.create_container()
    except:
        pass
        
    blob_client = container_client.get_blob_client(file_name)
    
    # Pour les fichiers volumineux, utiliser upload par morceaux
    chunk_size = 4 * 1024 * 1024
    
    if file_size > chunk_size * 2:
        # Upload en morceaux pour les gros fichiers
        with open(file_path, 'rb') as f:
            # Créer un blob avec des blocs
            block_list = []
            block_id = 1
            
            while True:
                read_data = f.read(chunk_size)
                if not read_data:
                    break
                
                # Créer un ID de bloc unique
                block_id_str = f"{block_id:08d}"
                encoded_block_id = base64.b64encode(block_id_str.encode()).decode()
                
                # Upload du bloc
                blob_client.stage_block(encoded_block_id, read_data)
                block_list.append(encoded_block_id)
                block_id += 1
            
            # Commiter tous les blocs
            blob_client.commit_block_list(block_list)
    else:
        # Upload direct pour les petits fichiers
        with open(file_path, 'rb') as file_content:
            blob_client.upload_blob(file_content.read(), overwrite=True)
    
    print(f"Uploaded {file_name} ({file_size/1024/1024:.1f} MB) to {container_name} container")
    
def process_csv_files(input_dir, output_dir, connection_string, container_name, max_workers=4):
    """Process all CSV files in the input directory"""
    # Get all CSV files
    csv_files = glob.glob(os.path.join(input_dir, "*.csv"))
    
    if not csv_files:
        print(f"No CSV files found in {input_dir}")
        return
    
    print(f"Found {len(csv_files)} CSV files to process")
    
    # Ajuste le nombre de workers selon la taille des fichiers
    total_size_gb = sum(os.path.getsize(f) for f in csv_files) / (1024**3)

    # Si taille totale > 2 GB, réduire le nombre de workers pour limiter l'utilisation mémoire
    if total_size_gb > 2:
        max_workers = min(max_workers, 2)
        print(f"Large files detected ({total_size_gb:.1f} GB), limiting to {max_workers} workers")
    

    # Process files in parallel
    with multiprocessing.Pool(max_workers) as pool:
        parquet_files = pool.starmap(
            convert_csv_to_parquet,
            [(csv_file, output_dir) for csv_file in csv_files]
        )
    
    # Upload all converted files to ADLS
    for parquet_file in parquet_files:
        upload_to_adls(parquet_file, connection_string, container_name)

def main():
    parser = argparse.ArgumentParser(description='Convert CSV files to Parquet and upload to ADLS')
    parser.add_argument('--input', required=True, help='Input directory containing CSV files')
    parser.add_argument('--output', default='./parquet_output', help='Output directory for Parquet files')
    parser.add_argument('--connection-string', help='Azure Storage connection string')
    parser.add_argument('--container', default='processed', help='ADLS container name')
    parser.add_argument('--workers', type=int, default=4, help='Number of worker processes')
    
    args = parser.parse_args()
    
    # For local development with Azurite
    if not args.connection_string:
        args.connection_string = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
    
    # Process all CSV files
    start_time = time.time()
    process_csv_files(
        args.input,
        args.output,
        args.connection_string,
        args.container,
        args.workers
    )
    elapsed_time = time.time() - start_time
    print(f"Total processing time: {elapsed_time:.2f} seconds")

if __name__ == "__main__":
    main()