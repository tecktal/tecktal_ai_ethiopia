#!/bin/bash
# Directus Setup Script for Linux/Mac
# Run this after: docker compose up -d

set -e

echo "🚀 Starting Directus setup..."

# Check if required files exist
if [ ! -f "snapshot.yaml" ]; then
    echo "❌ Error: snapshot.yaml not found!"
    echo "Please ensure snapshot.yaml is in the current directory."
    exit 1
fi

if [ ! -f "flows-data.sql" ]; then
    echo "❌ Error: flows-data.sql not found!"
    echo "Please ensure flows-data.sql is in the current directory."
    exit 1
fi

# Wait for services to be ready
echo "⏳ Waiting for services to initialize (30 seconds)..."
sleep 30

# Check if containers are running
if ! docker compose ps --services --filter "status=running" | grep -q "directus"; then
    echo "❌ Error: Directus container not running!"
    echo "Run 'docker compose up -d' first."
    exit 1
fi

if ! docker compose ps --services --filter "status=running" | grep -q "postgres"; then
    echo "❌ Error: Postgres container not running!"
    echo "Run 'docker compose up -d' first."
    exit 1
fi

# Apply schema
echo "📋 Applying database schema..."
docker cp snapshot.yaml directus-directus-1:/directus/snapshot.yaml
if docker compose exec directus npx directus schema apply --yes /directus/snapshot.yaml; then
    echo "✅ Schema applied successfully"
else
    echo "❌ Schema application failed"
    exit 1
fi

# Import flows
echo "⚡ Importing flows..."
if (echo "SET session_replication_role = replica;" && cat flows-data.sql && echo "SET session_replication_role = DEFAULT;") | docker compose exec -T postgres psql -U directus -d directus > /dev/null; then
    echo "✅ Flows imported successfully"
else
    echo "❌ Flows import failed"
    exit 1
fi

# Clean up registry extensions (removes broken marketplace extensions)
echo "🧹 Cleaning up registry extensions..."
docker compose exec postgres psql -U directus -d directus -c "DELETE FROM directus_extensions WHERE source = 'registry';" > /dev/null 2>&1 || true
echo "✅ Registry extensions cleaned"

# Fix admin permissions
echo "🔑 Configuring admin permissions..."
if docker compose exec postgres psql -U directus -d directus -c "UPDATE directus_users SET role = (SELECT id FROM directus_roles WHERE name = 'Administrator') WHERE email = 'admin@directus.com';" > /dev/null; then
    echo "✅ Admin permissions configured"
else
    echo "⚠️  Warning: Admin permission update failed"
fi

# Restart Directus
echo "🔄 Restarting Directus..."
docker compose restart directus > /dev/null
sleep 10

# Verify installation
echo ""
echo "📊 Verifying installation..."

FLOW_COUNT=$(docker compose exec postgres psql -U directus -d directus -t -c "SELECT COUNT(*) FROM directus_flows;" 2>/dev/null | tr -d '[:space:]')

if [ "$FLOW_COUNT" = "13" ]; then
    echo "✅ Flows: $FLOW_COUNT/13 imported"
else
    echo "⚠️  Flows: $FLOW_COUNT/13 imported (expected 13)"
fi

COLLECTION_COUNT=$(docker compose exec postgres psql -U directus -d directus -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE 'lms_%';" 2>/dev/null | tr -d '[:space:]')

if [ "$COLLECTION_COUNT" -gt 0 ]; then
    echo "✅ Collections: $COLLECTION_COUNT LMS tables found"
else
    echo "⚠️  Collections: No LMS tables found"
fi

EXTENSION_COUNT=$(docker compose exec postgres psql -U directus -d directus -t -c "SELECT COUNT(*) FROM directus_extensions WHERE source = 'local';" 2>/dev/null | tr -d '[:space:]')
echo "✅ Extensions: $EXTENSION_COUNT local extensions registered"

# Success message
echo ""
echo "🎉 Setup complete!"
echo ""
echo "Access Directus at: http://localhost:8055"
echo "Login with:"
echo "  Email: admin@directus.com"
echo "  Password: admin"
echo ""
echo "💡 Remember to change the admin password after first login!"