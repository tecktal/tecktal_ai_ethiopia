#!/bin/bash
sleep 20

# Apply schema first
npx directus schema apply --yes /directus/snapshot.yaml

# Then import flows
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_DATABASE -f /tmp/flows-data.sql 2>/dev/null || true

echo "Schema and flows imported!"