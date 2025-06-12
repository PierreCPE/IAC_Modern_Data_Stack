import logging
import azure.functions as func
import pandas as pd
import tempfile
import os
import time
from azure.storage.filedatalake import DataLakeServiceClient
from io import BytesIO

def main(myblob: func.InputStream):
    """
    Azure Function triggered by a new CSV file in the raw container.
    Converts the CSV to Parquet format and uploads to the processed container.
    
    Optimized for free tier by:
    - Processing in chunks to handle large files with limited memory
    - Using efficient compression
    """
    logging.info(f"Python blob trigger function processed blob: {myblob.name}")
    
    start_time = time.time()
    
    # Get connection string from environment variable
    conn_string = os.environ["STORAGE_CONNECTION_STRING"]
    
    # Extract file name without path
    file_name = os.path.basename(myblob.name)
    base_name = os.path.splitext(file_name)[0]
    
    # Connect to Data Lake Storage
    service_client = DataLakeServiceClient.from_connection_string(conn_string)
    file_system_client = service_client.get_file_system_client(file_system="processed")
    
    # Create a temporary file
    with tempfile.NamedTemporaryFile(suffix='.parquet') as tmp_file:
        try:
            # Read CSV in chunks to handle large files
            chunk_size = 100000  # Adjust based on your file size and memory limits
            
            # Create Parquet file from CSV data
            for i, chunk in enumerate(pd.read_csv(BytesIO(myblob.read()), chunksize=chunk_size)):
                mode = 'a' if i > 0 else 'w'
                chunk.to_parquet(
                    tmp_file.name,
                    engine='pyarrow',
                    compression='snappy',  # Good balance between speed and size
                    index=False,
                    mode=mode
                )
                logging.info(f"Processed chunk {i+1}")
            
            # Upload the Parquet file to the processed container
            output_file_path = f"{base_name}.parquet"
            file_client = file_system_client.get_file_client(output_file_path)
            
            # Reset file pointer to beginning
            tmp_file.seek(0)
            
            # Upload the file
            file_client.upload_data(tmp_file.read(), overwrite=True)
            
            elapsed_time = time.time() - start_time
            logging.info(f"Successfully converted {file_name} to Parquet in {elapsed_time:.2f} seconds")
            
        except Exception as e:
            logging.error(f"Error processing file {file_name}: {str(e)}")
            raise