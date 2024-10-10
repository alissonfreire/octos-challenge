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
mix ecto.setup

# Long live command
mix phx.server
