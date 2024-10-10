#!/bin/sh

set -e

# Setup env vars
cp .env.example .dev.env
cp .env.example .test.env

sed -i "s/DB_HOST=.*/DB_HOST=${DB_HOST:-postgres}/" .dev.env
sed -i "s/DB_HOST=.*/DB_HOST=${DB_HOST:-postgres}/" .test.env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=octos_challenge_test/" .test.env

source .dev.env

# check if PostgreSql is running
while ! pg_isready -q -h $DB_HOST -U $DB_USER
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

# Setup project dependencies and database
mix deps.get

# Create, migrate, and seed database if it doesn't exist.
HAS_DATABASE=`PGPASSWORD=$DB_PASS psql -U $DB_USER -h $DB_HOST -XtAc "SELECT 'ok' FROM pg_database WHERE datname='$DB_DATABASE'"`
if [ "$HAS_DATABASE" != "ok" ]; then
  echo "Database $DB_DATABASE does not exist. Creating..."
  mix ecto.setup
  echo "Database $DB_DATABASE created."
fi

# Long live command
mix phx.server
