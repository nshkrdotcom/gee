#!/bin/bash

# Script to extract comprehensive schema information from the ContextNexus PostgreSQL database.
# By default, it outputs to the console. File output is commented out.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
DEFAULT_DB_USER="contextnexus"
DEFAULT_DB_NAME="contextnexus"
DEFAULT_DB_HOST="localhost"
DEFAULT_DB_PORT="5432"
DEFAULT_DB_PASSWORD="your_strong_password" # From UBUNTU_SETUP.md

# --- Output file name (COMMENTED OUT FOR CONSOLE OUTPUT) ---
# TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# OUTPUT_DIR="db_schema_exports"
# SCHEMA_INFO_FILE="${OUTPUT_DIR}/contextnexus_schema_info_${TIMESTAMP}.txt"
# SCHEMA_DDL_FILE="${OUTPUT_DIR}/contextnexus_schema_ddl_${TIMESTAMP}.sql"

# --- Functions ---
print_info() {
    echo "[INFO] $1"
}

print_warning() {
    echo "[WARN] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
    exit 1
}

check_psql_pg_dump() {
    if ! command -v psql &> /dev/null; then
        print_error "psql command could not be found. Please install PostgreSQL client tools (e.g., sudo apt install postgresql-client)."
    fi
    if ! command -v pg_dump &> /dev/null; then
        print_error "pg_dump command could not be found. Please install PostgreSQL client tools (e.g., sudo apt install postgresql-client)."
    fi
}

clean_value() {
    echo "$1" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//'" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

parse_database_url() {
    local url_to_parse="$1"
    local cleaned_url
    # Remove potential outer quotes from the URL string itself first
    cleaned_url=$(clean_value "$url_to_parse")

    # Regex to parse DATABASE_URL: postgresql://user:password@host:port/dbname
    if [[ "$cleaned_url" =~ ^postgres(ql)?://([^:]*):?([^@]*)@([^:]*):([0-9]+)/([^?]*).*$ ]]; then
        DB_USER_FROM_URL=$(clean_value "${BASH_REMATCH[2]}")
        # Password can be empty or not present
        if [[ -n "${BASH_REMATCH[3]}" ]]; then
             DB_PASSWORD_FROM_URL=$(clean_value "${BASH_REMATCH[3]}")
        else
             DB_PASSWORD_FROM_URL=""
        fi
        DB_HOST_FROM_URL=$(clean_value "${BASH_REMATCH[4]}")
        DB_PORT_FROM_URL=$(clean_value "${BASH_REMATCH[5]}")
        DB_NAME_FROM_URL=$(clean_value "${BASH_REMATCH[6]}")
        print_info "Parsed DATABASE_URL: User='${DB_USER_FROM_URL}', Host='${DB_HOST_FROM_URL}', Port='${DB_PORT_FROM_URL}', DBName='${DB_NAME_FROM_URL}'"
        return 0
    else
        print_warning "Could not parse DATABASE_URL format: $cleaned_url"
        return 1
    fi
}

# --- Main Script ---
print_info "Starting ContextNexus Schema Exporter..."

check_psql_pg_dump

# Declare variables to hold parsed values from DATABASE_URL
DB_USER_FROM_URL=""
DB_PASSWORD_FROM_URL=""
DB_HOST_FROM_URL=""
DB_PORT_FROM_URL=""
DB_NAME_FROM_URL=""

# Attempt to load .env file if it exists
if [ -f ".env" ]; then
    print_info "Found .env file. Attempting to source DATABASE_URL..."
    if grep -q '^DATABASE_URL=' .env; then
        DATABASE_URL_FROM_ENV=$(grep '^DATABASE_URL=' .env | head -n 1 | cut -d '=' -f2-)
        if parse_database_url "$DATABASE_URL_FROM_ENV"; then
             print_info "DATABASE_URL processed from .env file."
        else
            print_warning "Failed to parse DATABASE_URL from .env. Will use defaults or other environment variables."
        fi
    else
        print_info "DATABASE_URL not found in .env file."
    fi
else
    print_info ".env file not found. Will use defaults or other environment variables."
fi

# Determine connection parameters (Shell Environment var > .env var > Default)
# Use temporary variables for values from shell environment to avoid PGPASSWORD conflict if it's already set for another purpose
PGUSER_ENV="${PGUSER}"
PGPASSWORD_ENV="${PGPASSWORD}" # Store current PGPASSWORD if set globally
PGHOST_ENV="${PGHOST}"
PGPORT_ENV="${PGPORT}"
PGDATABASE_ENV="${PGDATABASE}"

DB_USER=$(clean_value "${PGUSER_ENV:-${DB_USER_FROM_URL:-$DEFAULT_DB_USER}}")
# For password, prioritize PGPASSWORD_ENV (if set for this purpose), then from URL, then default
# The actual PGPASSWORD for the command will be set later
TARGET_DB_PASSWORD_TEMP="${DB_PASSWORD_FROM_URL:-$DEFAULT_DB_PASSWORD}"
if [ -n "$PGPASSWORD_ENV" ]; then
    TARGET_DB_PASSWORD_TEMP="$PGPASSWORD_ENV"
fi
TARGET_DB_PASSWORD=$(clean_value "$TARGET_DB_PASSWORD_TEMP")

DB_HOST=$(clean_value "${PGHOST_ENV:-${DB_HOST_FROM_URL:-$DEFAULT_DB_HOST}}")
DB_PORT=$(clean_value "${PGPORT_ENV:-${DB_PORT_FROM_URL:-$DEFAULT_DB_PORT}}")
DB_NAME=$(clean_value "${PGDATABASE_ENV:-${DB_NAME_FROM_URL:-$DEFAULT_DB_NAME}}")

# Set PGPASSWORD for the psql/pg_dump commands
export PGPASSWORD="$TARGET_DB_PASSWORD"

print_info "Using the following connection parameters for database '$DB_NAME':"
print_info "  User: $DB_USER"
print_info "  Host: $DB_HOST"
print_info "  Port: $DB_PORT"
# Avoid printing password directly for security. PGPASSWORD handles it.

# --- Create output directory (COMMENTED OUT FOR CONSOLE OUTPUT) ---
# mkdir -p "$OUTPUT_DIR"
# print_info "Output was configured to be saved in '$OUTPUT_DIR' directory."

# Common psql options for connecting (now an array)
PSQL_COMMON_ARGS=(-U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME")
PGDUMP_COMMON_ARGS=(-U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME")

# 1. Dump full DDL (schema only) using pg_dump to console
print_info "--- Full DDL Schema (pg_dump) ---"
if pg_dump "${PGDUMP_COMMON_ARGS[@]}" --schema-only --no-owner --no-privileges; then # Removed redirection
    print_info "DDL schema dump to console successful."
else
    # pg_dump might have printed an error already.
    print_error "pg_dump command failed. Check connection parameters and permissions. Ensure the user '$DB_USER' has necessary rights or PGPASSWORD is correct."
fi
echo ""
echo "--- End of DDL Schema ---"
echo ""

# 2. Get detailed information using psql meta-commands to console
print_info "--- Detailed Schema Information (psql) ---"

( # Start a subshell for grouping psql outputs
    echo "=== PostgreSQL Server Version ==="
    psql "${PSQL_COMMON_ARGS[@]}" -tc "SELECT version();" # Use -t for tuples only, -c for command
    echo ""

    echo "=== Connection Info ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\conninfo"
    echo ""

    echo "=== List of Databases (from current connection context) ==="
    psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -lqt # Use -l for listing DBs, no -d needed
    echo ""

    echo "=== Current Database Details ($DB_NAME) ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\l+ \"$DB_NAME\""
    echo ""

    echo "=== Schemas (Namespaces) in '$DB_NAME' ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\dn+"
    echo ""

    echo "=== Tables (in all user schemas of '$DB_NAME') ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\dt+ *.*"
    echo ""

    echo "=== Views (in all user schemas of '$DB_NAME') ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\dv+ *.*"
    echo ""

    echo "=== Materialized Views (in all user schemas of '$DB_NAME') ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\dm+ *.*"
    echo ""
    
    echo "=== Sequences (in all user schemas of '$DB_NAME') ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\ds+ *.*"
    echo ""

    echo "=== Indexes (in all user schemas of '$DB_NAME') ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\di+ *.*"
    echo ""

    echo "=== Foreign Tables (in all user schemas of '$DB_NAME') ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\det+ *.*"
    echo ""

    echo "=== Functions (in all user schemas of '$DB_NAME') ==="
    psql "${PSQL_COMMON_ARGS[@]}" -tc "SELECT n.nspname as schema_name, p.proname as function_name, pg_get_function_result(p.oid) as result_data_type, pg_get_function_arguments(p.oid) as argument_data_types, CASE p.prokind WHEN 'a' THEN 'agg' WHEN 'w' THEN 'window' WHEN 'p' THEN 'proc' ELSE 'func' END as type FROM pg_proc p LEFT JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname <> 'pg_catalog' AND n.nspname <> 'information_schema' ORDER BY schema_name, function_name;"
    echo ""
    
    echo "=== Triggers (in '$DB_NAME') ==="
    psql "${PSQL_COMMON_ARGS[@]}" -tc "SELECT event_object_schema AS trigger_schema, event_object_table AS trigger_table, trigger_name, event_manipulation, action_statement, action_timing FROM information_schema.triggers WHERE trigger_catalog = '$DB_NAME' ORDER BY trigger_schema, trigger_table;"
    echo ""

    echo "=== Roles (Users and Groups) on Server ==="
    psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -c "\du+" # no -d needed
    echo ""

    echo "=== Extensions installed in '$DB_NAME' ==="
    psql "${PSQL_COMMON_ARGS[@]}" -c "\dx+"
    echo ""

    echo "=== Table Details (Columns, Indexes, Constraints, Triggers) in '$DB_NAME' ==="
    TABLE_SCHEMAS=$(psql "${PSQL_COMMON_ARGS[@]}" -Atc "SELECT DISTINCT schemaname FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema');" | grep -v '^$' | grep -v 'rows)')
    
    if [ -z "$TABLE_SCHEMAS" ]; then
        TABLE_SCHEMAS="public" # Default to public if no other user schemas found
        print_info "No specific user schemas found, defaulting to 'public' for table details."
    fi

    for schema_name_raw in $TABLE_SCHEMAS; do
      schema_name=$(clean_value "$schema_name_raw")
      print_info "Describing tables in schema: $schema_name"
      TABLES_IN_SCHEMA=$(psql "${PSQL_COMMON_ARGS[@]}" -Atc "SELECT tablename FROM pg_tables WHERE schemaname = '$schema_name';" | grep -v '^$' | grep -v 'rows)')
      if [ -n "$TABLES_IN_SCHEMA" ]; then
          for table_name_raw in $TABLES_IN_SCHEMA; do
              table_name=$(clean_value "$table_name_raw")
              echo "--- Schema: \"$schema_name\", Table: \"$table_name\" ---"
              psql "${PSQL_COMMON_ARGS[@]}" -E -c "\d+ \"$schema_name\".\"$table_name\""
              echo ""
          done
      else
          print_info "No tables found in schema '$schema_name'."
      fi
    done

) # Removed file redirection here. Output goes to console.

# Check if psql commands were successful (set -e handles this now for console output)
# If any psql command above fails, the script will exit due to set -e.

# --- Unset PGPASSWORD (good practice) ---
unset PGPASSWORD

print_info "Schema export to console complete."
echo "Done."
