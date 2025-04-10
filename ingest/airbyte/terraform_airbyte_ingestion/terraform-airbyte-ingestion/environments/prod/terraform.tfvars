# Terraform variables for the production environment

airbyte_image = "airbyte/airbyte:latest"
airbyte_db_url = "postgresql://admin:admin@postgres:5432/mydatabase"
network_name = "prod-network"
region = "us-west-2"
instance_type = "t2.micro"
desired_capacity = 2
max_size = 3
min_size = 1