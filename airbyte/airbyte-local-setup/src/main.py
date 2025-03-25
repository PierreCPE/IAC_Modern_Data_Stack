import airbyte_lib as ab
import os
from datetime import datetime
# from utils.airbyte_helper import setup_csv_to_adls
import matplotlib.pyplot as plt



def convert_csv_to_parquet_spark(csv_path, parquet_path):
    """Convert a CSV file to Parquet format using PySpark."""
    spark = SparkSession.builder.appName("CSVToParquet").getOrCreate()
    df = spark.read.csv(csv_path, header=True, inferSchema=True)
    df.write.parquet(parquet_path, mode="overwrite")
    print(f"Converted {csv_path} to {parquet_path} using PySpark")

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


    products_df = read_results.streams["products"].to_pandas()
    print(products_df.head())


    # Problemes d'affchage de l'histogramme : 



    users_df = read_results.streams["users"].to_pandas()
    print(users_df.head())
    
    plt.hist(users_df["age"], bins=10, edgecolor="black")
    plt.title("Histogram of Ages")
    plt.xlabel("Ages")
    plt.ylabel("frequency")

    # Create a dedicated folder for histograms if it doesn't exist
    output_dir = "histograms"
    os.makedirs(output_dir, exist_ok=True)

    # Generate a timestamped filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"histogram_{timestamp}.png"
    filepath = os.path.join(output_dir, filename)

    # Save the graph to the dedicated folder
    plt.savefig(filepath)
    print(f"Graph saved to {filepath}")
    

    # # Process each stream
    # for name, records in result.streams.items():
    #     print(f"Stream {name}: {len(list(records))} records")

    #     # Save the records to a CSV file
    #     csv_path = f"data/{name}.csv"
    #     with open(csv_path, "w") as f:
    #         for record in records:
    #             f.write(",".join(map(str, record.values())) + "\n")
    #     print(f"Saved stream {name} to {csv_path}")

    #     # Convert the CSV file to Parquet
    #     parquet_path = f"data/{name}.parquet"
    #     convert_csv_to_parquet_spark(csv_path, parquet_path)

    #     # Upload the Parquet file to Azurite
    #     container_name = "my-container"
    #     setup_csv_to_adls(None, parquet_path, container_name)

if __name__ == "__main__":
    main()