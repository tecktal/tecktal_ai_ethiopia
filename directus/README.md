# Directus Custom Project

A complete Directus-based LMS application with RAG service, PDF processing, flows automation, and custom extensions.

## Prerequisites

- Docker and Docker Compose
- OpenAI API key (for RAG service)

## Quick Start

### 1. Download the project files

Save `docker-compose.yml` and `.env.example` to a folder.

### 2. Configure environment

Create `.env` file:
```bash
# Windows PowerShell
cp .env.example .env

# Linux/Mac
cp .env.example .env
```

Edit `.env` and add your OpenAI API key:
```
OPENAI_API_KEY=sk-your-actual-key-here
```

### 3. Update credentials (Optional but Recommended)

For production, update `docker-compose.yml` with secure credentials:

Generate secure keys:
```bash
# Linux/Mac
openssl rand -base64 32  # Use for KEY
openssl rand -base64 32  # Use for SECRET

# Windows PowerShell
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
```

Update in `docker-compose.yml`:
- `KEY`: your-generated-key
- `SECRET`: your-generated-secret
- `ADMIN_EMAIL`: your-email@domain.com
- `ADMIN_PASSWORD`: YourStrongPassword123!

### 4. Start the application

```bash
docker compose up -d
```

### 5. Run setup script (AUTOMATED SETUP)

After containers start, run the setup script to configure everything automatically:

#### Windows PowerShell:
```powershell
.\setup.ps1
```

#### Linux/Mac:
```bash
chmod +x setup.sh
./setup.sh
```

The script will:
- ✅ Apply database schema
- ✅ Import all 13 flows
- ✅ Configure admin permissions
- ✅ Verify installation
- ✅ Display login credentials

**Manual Setup (Alternative)**

If you prefer to run commands manually, see the [Manual Setup](#manual-setup-alternative) section below.

### 6. Access Directus

Open http://localhost:8055

Login with:
- Email: `admin@directus.com` (or what you set)
- Password: `admin` (or what you set)

Navigate to:
- **Settings > Data Model** - See all collections
- **Settings > Flows** - See all 13 automated flows
- **Content > Courses** - Start managing LMS content

## Architecture

### Services

| Service | Port | Description |
|---------|------|-------------|
| Directus | 8055 | Headless CMS with custom extensions |
| PostgreSQL | 5432 (internal) | Database |
| Qdrant | 6333, 6334 | Vector database for RAG |
| RAG Service | 8000 | AI-powered search and retrieval |
| PDF Service | 8001 | PDF processing service |

### Features

**Directus Extensions:**
- Chat interface
- HTML editor with math support
- Math WYSIWYG editor
- Custom input fields

**Automated Flows (13 total):**
- Generate lesson plan
- Create lessons
- Create assignments
- Generate modules for course
- Generate lessons for module
- Generate content for lesson
- Generate assignments
- Generate simulations
- Generate description for course
- PDF processing and loop
- Update lesson plan PDF

**Collections:**
- LMS courses, modules, lessons
- Instructors and enrollments
- Assignments and simulations
- Quiz and question bank
- Comments and reviews
- Settings and topics

## Management Commands

### Check service status
```bash
docker compose ps
```

### View logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs directus
docker compose logs rag-service
docker compose logs pdf-service
docker compose logs postgres
```

### Restart services
```bash
# All services
docker compose restart

# Specific service
docker compose restart directus
```

### Stop services
```bash
docker compose down
```

### Stop and remove all data (⚠️ CAREFUL!)
```bash
docker compose down -v
```

## Database Operations

### Backup database
```bash
# Windows PowerShell
docker compose exec postgres pg_dump -U directus directus > backup_$(Get-Date -Format "yyyyMMdd").sql

# Linux/Mac
docker compose exec postgres pg_dump -U directus directus > backup_$(date +%Y%m%d).sql
```

### Restore database
```bash
# Windows PowerShell
Get-Content backup_file.sql | docker compose exec -T postgres psql -U directus directus

# Linux/Mac
cat backup_file.sql | docker compose exec -T postgres psql -U directus directus
```

### Access database directly
```bash
docker compose exec postgres psql -U directus -d directus
```

### Check flows
```bash
docker compose exec postgres psql -U directus -d directus -c "SELECT id, name, status FROM directus_flows;"
```

## Troubleshooting

### Issue: Directus container exits immediately

**Solution:** Check logs
```bash
docker compose logs directus
```

Common causes:
- Database not ready (wait 10 seconds and try again)
- Invalid environment variables
- Port 8055 already in use

### Issue: Flows not showing in UI

**Solution:** Re-import flows
```bash
# Windows
@"
SET session_replication_role = replica;
$(Get-Content flows-data.sql -Raw)
SET session_replication_role = DEFAULT;
"@ | docker compose exec -T postgres psql -U directus -d directus

# Linux/Mac
(echo "SET session_replication_role = replica;" && cat flows-data.sql && echo "SET session_replication_role = DEFAULT;") | docker compose exec -T postgres psql -U directus directus
```

### Issue: RAG service unhealthy

**Solution:** Check OpenAI API key
```bash
docker compose logs rag-service
```

Make sure `OPENAI_API_KEY` is set correctly in `.env`

### Issue: Collections show "FORBIDDEN" or permission errors

**Solution:** Admin role not properly assigned
```bash
# Windows PowerShell
docker compose exec postgres psql -U directus -d directus -c "UPDATE directus_users SET role = (SELECT id FROM directus_roles WHERE name = 'Administrator') WHERE email = 'admin@directus.com';"
docker compose restart directus

# Linux/Mac  
docker compose exec postgres psql -U directus -d directus -c "UPDATE directus_users SET role = (SELECT id FROM directus_roles WHERE name = 'Administrator') WHERE email = 'admin@directus.com';"
docker compose restart directus
```

Then logout and login again.

### Issue: Permission denied on volumes (Linux/Mac)

**Solution:**
```bash
sudo chown -R $USER:$USER .
```

### Issue: Port conflicts

**Solution:** Change ports in `docker-compose.yml`
```yaml
ports:
  - "8056:8055"  # Change 8055 to 8056
```

## Updating

### Pull latest images
```bash
docker compose pull
docker compose up -d
```

### Rebuild after changes
```bash
docker compose up -d --build
```

## Data Persistence

All data is stored in Docker volumes:
- `postgres_data`: Database
- `directus_uploads`: Uploaded files
- `qdrant_storage`: Vector embeddings
- `model_cache`: AI model cache

**To backup everything:**
```bash
# Database
docker compose exec postgres pg_dump -U directus directus > backup.sql

# Uploads (copy volume contents)
docker compose cp directus:/directus/uploads ./uploads_backup
```

## Development

### Export schema after changes
```bash
docker compose exec directus npx directus schema snapshot ./snapshot.yaml
docker compose cp directus:/directus/snapshot.yaml ./
```

### Export flows after changes
```bash
docker compose exec postgres pg_dump -U directus directus \
  --data-only \
  --disable-triggers \
  --table='directus_flows' \
  --table='directus_operations' \
  > flows-data.sql
```

## API Access

### Directus API
```
http://localhost:8055/items/lms_courses
```

### RAG Service
```
http://localhost:8000/docs
```

### PDF Service
```
http://localhost:8001/docs
```

## Security Recommendations

1. **Change default admin password** immediately after first login
2. **Use strong KEY and SECRET** values in production
3. **Set proper CORS origins** instead of `'true'`
4. **Don't expose database port** publicly
5. **Keep your OpenAI API key secret**

## Support

For issues:
1. Check logs: `docker compose logs [service]`
2. Verify all containers running: `docker compose ps`
3. Review this troubleshooting guide
4. Check Directus documentation: https://docs.directus.io

## License

[Your License Here]

---

## Manual Setup (Alternative)

If you prefer not to use the automated setup script, follow these steps after running `docker compose up -d`:

### Windows PowerShell:
```powershell
# Wait for services
Start-Sleep -Seconds 30

# Apply schema
docker cp snapshot.yaml directus-directus-1:/directus/snapshot.yaml
docker compose exec directus npx directus schema apply --yes /directus/snapshot.yaml

# Import flows
@"
SET session_replication_role = replica;
$(Get-Content flows-data.sql -Raw)
SET session_replication_role = DEFAULT;
"@ | docker compose exec -T postgres psql -U directus -d directus

# Fix admin permissions
docker compose exec postgres psql -U directus -d directus -c "UPDATE directus_users SET role = (SELECT id FROM directus_roles WHERE name = 'Administrator') WHERE email = 'admin@directus.com';"

# Restart
docker compose restart directus
```

### Linux/Mac:
```bash
# Wait for services
sleep 30

# Apply schema
docker cp snapshot.yaml directus-directus-1:/directus/snapshot.yaml
docker compose exec directus npx directus schema apply --yes /directus/snapshot.yaml

# Import flows
(echo "SET session_replication_role = replica;" && cat flows-data.sql && echo "SET session_replication_role = DEFAULT;") | docker compose exec -T postgres psql -U directus -d directus

# Fix admin permissions
docker compose exec postgres psql -U directus -d directus -c "UPDATE directus_users SET role = (SELECT id FROM directus_roles WHERE name = 'Administrator') WHERE email = 'admin@directus.com';"

# Restart
docker compose restart directus
```