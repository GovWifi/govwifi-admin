#!/bin/bash
set -euo pipefail

LOGGING_API_REPO="${LOGGING_API_REPO:-https://github.com/GovWifi/govwifi-logging-api.git}"
LOGGING_API_REF="${LOGGING_API_REF:-master}"

echo "==> Resolving logging API ref: $LOGGING_API_REF..."
COMMIT_SHA=$(git ls-remote "$LOGGING_API_REPO" "$LOGGING_API_REF" | head -1 | cut -f1)

if [ -z "$COMMIT_SHA" ]; then
  echo "ERROR: Could not resolve ref '$LOGGING_API_REF' from $LOGGING_API_REPO"
  exit 1
fi

CLONE_DIR="/tmp/logging-api-${COMMIT_SHA}"
MIGRATIONS_DIR="${CLONE_DIR}/mysql/migrations"
export MIGRATIONS_DIR

if [ -d "$CLONE_DIR" ]; then
  echo "==> Using cached clone at $CLONE_DIR"
else
  echo "==> Cloning logging API repo (ref: $LOGGING_API_REF, sha: $COMMIT_SHA)..."
  git clone --depth 1 --branch "$LOGGING_API_REF" "$LOGGING_API_REPO" "$CLONE_DIR"
fi

echo "==> Waiting for MySQL to be ready..."
ruby -e "
  require 'sequel'
  until (Sequel.connect(adapter: 'mysql2', host: ENV['DB_HOSTNAME'], port: ENV.fetch('DB_PORT', 3306), user: ENV['DB_USER'], password: ENV['DB_PASS'], ssl_mode: 'DISABLED').test_connection rescue false)
    puts '   waiting...'
    sleep 2
  end
"

echo "==> Running Sequel migrations..."
ruby -e "
  require 'sequel'
  Sequel.extension :migration

  db = Sequel.connect(
    adapter: 'mysql2',
    host: ENV['DB_HOSTNAME'],
    port: ENV.fetch('DB_PORT', 3306),
    database: ENV['DB_NAME'],
    user: ENV['DB_USER'],
    password: ENV['DB_PASS'],
    ssl_mode: 'DISABLED'
  )

  Sequel::Migrator.run(db, ENV['MIGRATIONS_DIR'])
  puts '==> Migrations complete.'
"
