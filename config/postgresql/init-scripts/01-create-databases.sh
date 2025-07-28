#!/bin/bash
set -e

# Create databases for various services
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create Grafana database
    CREATE DATABASE grafana;
    CREATE SCHEMA IF NOT EXISTS grafana;
    GRANT ALL PRIVILEGES ON DATABASE grafana TO $POSTGRES_USER;
    
    -- Create n8n database
    CREATE DATABASE n8n;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO $POSTGRES_USER;
    
    -- Create litellm database
    CREATE DATABASE litellm;
    CREATE SCHEMA IF NOT EXISTS litellm;
    GRANT ALL PRIVILEGES ON DATABASE litellm TO $POSTGRES_USER;
    
    -- Create additional databases if needed
    -- CREATE DATABASE other_service;
    -- GRANT ALL PRIVILEGES ON DATABASE other_service TO $POSTGRES_USER;
EOSQL

echo "Databases created successfully"