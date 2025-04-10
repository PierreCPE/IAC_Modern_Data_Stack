terraform {
  required_providers {
    airbyte = {
      source = "airbytehq/airbyte"
      version = "0.9.0"
    }
  }
}

provider "airbyte" {
    // highlight-start
    client_id = var.client_id
    client_secret = var.client_secret

    # Include server_url if running locally
    server_url = "http://localhost:8000/api/public/v1/"
    // highlight-end
}

resource "airbyte_source_faker" "my_source" {
  configuration = {
    count = 10
    # other configuration parameters
  }
  name = "My Faker Source"
  workspace_id = var.workspace_id
}

# Then reference it by the generated source_id
data "airbyte_source_faker" "my_source_faker" {
  source_id = airbyte_source_faker.my_source.source_id
}