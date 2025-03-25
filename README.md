# Data Pipeline Project

## Introduction

Ce projet met en place une architecture de pipeline de données basée sur les technologies suivantes :

- **Airbyte** : ingestion des données depuis différentes sources
- **Azure Data Lake Storage Gen 2 (ADLS Gen 2)** : stockage des données en format Parquet
- **Snowflake** : entrepôt de données pour transformation et analyse
- **dbt (Data Build Tool)** : transformation des données (Bronze → Silver → Gold)
- **Metabase** : visualisation des données
- **Terraform** : gestion de l'infrastructure en tant que code (IaC)

## Architecture



## Installation et Configuration

### 1️⃣ Prérequis

Avant de démarrer, installez les éléments suivants :

- [Docker](https://www.docker.com/)
- [Python](https://www.python.org/) (pour dbt)
- [Terraform](https://www.terraform.io/)
- [VS Code](https://code.visualstudio.com/) avec les extensions :
  - **Python**
  - **Terraform**
  - **Docker**
  - **GitLens**

### 2️⃣ Cloner le projet

```bash
git clone <URL_GIT>
cd my-data-pipeline
```

### 3️⃣ Lancer Airbyte

```bash
cd airbyte
docker-compose up -d
```

Airbyte sera disponible sur [http://localhost:8000](http://localhost:8000).

### 4️⃣ Lancer le stockage ADLS Gen 2 (Azurite en local)

```bash
docker run -p 10000:10000 -p 10001:10001 -p 10002:10002 mcr.microsoft.com/azure-storage/azurite
```

### 5️⃣ Configurer Snowflake (ou PostgreSQL en local)

```bash
docker run --name postgres -e POSTGRES_PASSWORD=yourpassword -p 5432:5432 -d postgres
```

### 6️⃣ Installer et exécuter dbt

```bash
pip install dbt-core dbt-postgres
cd dbt
dbt debug
dbt run
```

### 7️⃣ Lancer Metabase

```bash
docker run -d -p 3000:3000 --name metabase metabase/metabase
```

Accédez à [http://localhost:3000](http://localhost:3000) et connectez-vous.

## Automatisation avec Terraform

Une fois la version locale validée, nous utiliserons Terraform pour déployer l'infrastructure sur Azure et Snowflake.

## Contribuer

1. Forkez le repo
2. Créez une branche (`feature-nom`)
3. Faites un commit et un push
4. Ouvrez une PR

## Licence

MIT License

