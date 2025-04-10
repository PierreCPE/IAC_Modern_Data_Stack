# Terraform Airbyte Ingestion

This project is designed to facilitate the ingestion of data using Airbyte, leveraging Terraform for infrastructure as code. The setup includes modules for Airbyte and networking, as well as separate configurations for development and production environments.

## Project Structure

- **modules/**: Contains reusable Terraform modules.
  - **airbyte/**: Module for setting up Airbyte ingestion.
    - `main.tf`: Main configuration for Airbyte resources.
    - `variables.tf`: Input variables for customizing the Airbyte module.
    - `outputs.tf`: Output values from the Airbyte module.
  - **network/**: Module for networking resources.
    - `main.tf`: Main configuration for network resources.
    - `variables.tf`: Input variables for customizing the network setup.
    - `outputs.tf`: Output values from the network module.

- **environments/**: Contains environment-specific configurations.
  - **dev/**: Development environment configuration.
    - `main.tf`: Main configuration for the development setup.
    - `variables.tf`: Input variables for the development environment.
    - `terraform.tfvars`: Values for the development environment variables.
  - **prod/**: Production environment configuration.
    - `main.tf`: Main configuration for the production setup.
    - `variables.tf`: Input variables for the production environment.
    - `terraform.tfvars`: Values for the production environment variables.

- **main.tf**: Entry point for the Terraform configuration, defining the overall infrastructure setup.
- **variables.tf**: Global input variables for the entire Terraform project.
- **outputs.tf**: Global output values for the entire Terraform project.
- **terraform.tfstate**: Current state of the infrastructure managed by Terraform.
- **terraform.tfstate.backup**: Backup of the previous state of the infrastructure.

## Getting Started

1. **Prerequisites**: Ensure you have Terraform installed on your machine.
2. **Clone the Repository**: Clone this repository to your local machine.
3. **Navigate to the Project Directory**: Change into the project directory.
4. **Initialize Terraform**: Run `terraform init` to initialize the Terraform configuration.
5. **Plan the Infrastructure**: Use `terraform plan` to see the resources that will be created.
6. **Apply the Configuration**: Execute `terraform apply` to create the resources defined in the configuration.

## Usage

Customize the input variables in the `variables.tf` files located in the respective modules and environments to suit your needs. After making changes, remember to run `terraform plan` and `terraform apply` to update your infrastructure.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.