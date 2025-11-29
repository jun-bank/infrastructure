#!/bin/bash
set -e

echo "=== Jun Bank PostgreSQL Initialization ==="

# 데이터베이스 목록
DATABASES=(
    "account_db"
    "transaction_db"
    "transfer_db"
    "card_db"
    "ledger_db"
    "user_db"
    "auth_db"
)

# 각 데이터베이스 생성 및 pgvector 확장 활성화
for db in "${DATABASES[@]}"; do
    echo "Creating database: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE DATABASE $db;
EOSQL

    echo "Enabling pgvector extension on: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
        CREATE EXTENSION IF NOT EXISTS vector;
EOSQL

    # DB별 사용자 생성 (db_name에서 _db 제거)
    db_user="${db%_db}"
    db_password="${db_user}"

    echo "Creating user: $db_user"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$db_user') THEN
                CREATE ROLE $db_user WITH LOGIN PASSWORD '$db_password';
            END IF;
        END
        \$\$;
        GRANT ALL PRIVILEGES ON DATABASE $db TO $db_user;
EOSQL

    # 스키마 권한 부여
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
        GRANT ALL ON SCHEMA public TO $db_user;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $db_user;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $db_user;
EOSQL

    echo "Database $db initialized successfully"
done

echo "=== All databases initialized ==="