# filepath: airbyte-local-setup/README.md
# Airbyte Local Setup

## Introduction

This project sets up Airbyte locally using the Airbyte Python library instead of Docker Compose. It provides a simple way to manage data ingestion from various sources.

## Project Structure

```
airbyte-local-setup/
├── src/
│   ├── main.py          # Entry point of the application
│   └── utils/
│       └── airbyte_helper.py  # Helper functions for Airbyte API interactions
├── requirements.txt     # Project dependencies
└── README.md            # Project documentation
```

## Installation

1. Clone the repository:
   ```bash
   git clone <URL_GIT>
   cd airbyte-local-setup
   ```

2. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

To run the application, execute the following command:
```bash
python src/main.py
```

## Airbyte Setup

This project utilizes the Airbyte Python client to manage data ingestion. Ensure you have the necessary configurations set up in your `main.py` file to connect to your data sources.

## Contributing

1. Fork the repository
2. Create a branch (`feature-name`)
3. Make your changes and commit them
4. Push to your branch and open a pull request

## License

This project is licensed under the MIT License.