# Directus Custom Project

A complete Directus-based application with RAG service, PDF processing, and custom extensions.

## Prerequisites

- Docker and Docker Compose
- OpenAI API key

## Quick Start

1. **Clone this repository**
```bash
   git clone <your-repo-url>
   cd <repo-name>
```

2. **Configure environment**
```bash
   cp .env.example .env
```
   
   Edit `.env` and add your OpenAI API key:
```
   OPENAI_API_KEY=sk-your-actual-key-here
```

3. **Update credentials in docker-compose.yml**
   
   Generate secure keys:
```bash
   openssl rand -base64 32  # Use for KEY
   openssl rand -base64 32  # Use for SECRET
```
   
   Edit `docker-compose.yml` and update:
   - `KEY`: (generated above)
   - `SECRET`: (generated above)
   - `ADMIN_EMAIL`: your email
   - `ADMIN_PASSWORD`: strong password

4. **Start the application**
```bash
   docker compose up -d
```

5. **Wait for initialization**
```bash
   docker compose logs -f
```

6. **Access Directus**
   
   Open http://localhost:8055
   
   Login with the credentials you set in docker-compose.yml

## Architecture

- **Directus** (Port 8055): Headless CMS with custom extensions
- **PostgreSQL** (Port 5432): Database
- **Qdrant** (Ports 6333-6334): Vector database for RAG
- **RAG Service** (Port 8000): AI-powered search and retrieval
- **PDF Service** (Port 8001): PDF processing service

## Services

### Directus
Custom Directus instance with:
- Pre-configured schema (collections, fields, relations)
- Custom extensions for chat, HTML editor, and math WYSIWYG
- Flows for automation

### RAG Service
AI-powered retrieval augmented generation service for:
- Document embedding
- Semantic search
- Context-aware responses

### PDF Service
PDF processing capabilities:
- Text extraction
- Metadata parsing
- Database integration

## Management Commands

### View logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f directus
docker compose logs -f rag-service
docker compose logs -f pdf-service
```

### Check status
```bash
docker compose ps
```

### Restart services
```bash
docker compose restart
```

### Stop services
```bash
docker compose down
```

### Stop and remove all data (CAREFUL!)
```bash
docker compose down -v
```

### Backup database
```bash
docker exec directus-postgres-1 pg_dump -U directus directus > backup_$(date +%Y%m%d).sql
```

### Restore database
```bash
cat backup_file.sql | docker exec -i directus-postgres-1 psql -U directus directus
```

## Development

### Update schema
After making changes in Directus admin:
```bash
docker exec directus-directus-1 npx directus schema snapshot --yes ./snapshot.yaml
docker cp directus-directus-1:/directus/snapshot.yaml ./snapshot.yaml
```

### Rebuild services after code changes
```bash
docker compose up -d --build
```

## Troubleshooting

### Directus won't start
- Check database connection
- Verify environment variables
- Check logs: `docker compose logs directus`

### Schema not applied
Run initialization manually:
```bash
docker compose run --rm directus npx directus schema apply --yes /directus/snapshot.yaml
```

### RAG service issues
- Verify OpenAI API key is set
- Check Qdrant is running
- View logs: `docker compose logs rag-service`

### Permission issues with volumes
```bash
sudo chown -R $USER:$USER postgres_data/ qdrant_storage/ uploads/
```

## Updating

Pull latest images:
```bash
docker compose pull
docker compose up -d
```

## License

[Your License Here]

## Support

For issues or questions, contact: [your-email]
