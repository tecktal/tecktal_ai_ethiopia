# Directus Setup Script for Windows
# Run this after: docker compose up -d

Write-Host "[*] Starting Directus setup..." -ForegroundColor Cyan

# Check if required files exist
if (-not (Test-Path "snapshot.yaml")) {
    Write-Host "[ERROR] snapshot.yaml not found!" -ForegroundColor Red
    Write-Host "Please ensure snapshot.yaml is in the current directory." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path "flows-data.sql")) {
    Write-Host "[ERROR] flows-data.sql not found!" -ForegroundColor Red
    Write-Host "Please ensure flows-data.sql is in the current directory." -ForegroundColor Yellow
    exit 1
}

# Wait for services to be ready
Write-Host "[*] Waiting for services to initialize (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check if containers are running
$directusRunning = docker compose ps --services --filter "status=running" | Select-String -Pattern "directus"
$postgresRunning = docker compose ps --services --filter "status=running" | Select-String -Pattern "postgres"

if (-not $directusRunning -or -not $postgresRunning) {
    Write-Host "[ERROR] Containers not running!" -ForegroundColor Red
    Write-Host "Run 'docker compose up -d' first." -ForegroundColor Yellow
    exit 1
}

# Apply schema
Write-Host "[*] Applying database schema..." -ForegroundColor Cyan
docker cp snapshot.yaml directus-directus-1:/directus/snapshot.yaml
docker compose exec directus npx directus schema apply --yes /directus/snapshot.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Schema applied successfully" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Schema application failed" -ForegroundColor Red
    exit 1
}

# Import flows
Write-Host "[*] Importing flows..." -ForegroundColor Cyan
$flowsContent = Get-Content flows-data.sql -Raw
$importCommand = @"
SET session_replication_role = replica;
$flowsContent
SET session_replication_role = DEFAULT;
"@

$importCommand | docker compose exec -T postgres psql -U directus -d directus | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Flows imported successfully" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Flows import failed" -ForegroundColor Red
    exit 1
}

# Clean up registry extensions (removes broken marketplace extensions)
Write-Host "[*] Cleaning up registry extensions..." -ForegroundColor Cyan
docker compose exec postgres psql -U directus -d directus -c "DELETE FROM directus_extensions WHERE source = 'registry';" 2>$null | Out-Null
Write-Host "[OK] Registry extensions cleaned" -ForegroundColor Green

# Fix admin permissions
Write-Host "[*] Configuring admin permissions..." -ForegroundColor Cyan
docker compose exec postgres psql -U directus -d directus -c "UPDATE directus_users SET role = (SELECT id FROM directus_roles WHERE name = 'Administrator') WHERE email = 'admin@directus.com';" | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Admin permissions configured" -ForegroundColor Green
} else {
    Write-Host "[WARN] Admin permission update failed" -ForegroundColor Yellow
}

# Restart Directus
Write-Host "[*] Restarting Directus..." -ForegroundColor Cyan
docker compose restart directus | Out-Null
Start-Sleep -Seconds 10

# Verify installation
Write-Host ""
Write-Host "[*] Verifying installation..." -ForegroundColor Cyan

$flowCount = docker compose exec postgres psql -U directus -d directus -t -c "SELECT COUNT(*) FROM directus_flows;" 2>$null
if ($flowCount) {
    $flowCount = $flowCount.Trim()
    if ($flowCount -eq "13") {
        Write-Host "[OK] Flows: $flowCount/13 imported" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Flows: $flowCount/13 imported (expected 13)" -ForegroundColor Yellow
    }
}

$collectionCheck = docker compose exec postgres psql -U directus -d directus -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE 'lms_%';" 2>$null
if ($collectionCheck) {
    $count = ($collectionCheck | Select-Object -First 1).Trim()
    try {
        $numCount = [int]$count
        if ($numCount -gt 0) {
            Write-Host "[OK] Collections: $numCount LMS tables found" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Collections: No LMS tables found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[INFO] Collections: Verification skipped" -ForegroundColor Cyan
    }
}

$extensionCount = docker compose exec postgres psql -U directus -d directus -t -c "SELECT COUNT(*) FROM directus_extensions WHERE source = 'local';" 2>$null
if ($extensionCount) {
    $extensionCount = $extensionCount.Trim()
    Write-Host "[OK] Extensions: $extensionCount local extensions registered" -ForegroundColor Green
}

# Success message
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access Directus at: http://localhost:8055" -ForegroundColor Cyan
Write-Host "Login with:" -ForegroundColor Cyan
Write-Host "  Email: admin@directus.com" -ForegroundColor White
Write-Host "  Password: admin" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Change the admin password after first login!" -ForegroundColor Yellow
Write-Host ""