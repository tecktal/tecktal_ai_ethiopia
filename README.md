# Tecktal AI Ethiopia - LMS Platform

An open-source Learning Management System powered by Directus CMS with AI-powered content generation and an intelligent research assistant.

## Overview

This project consists of two main components:

| Component | Description | Port |
|-----------|-------------|------|
| **Directus LMS** | Headless CMS with custom extensions for course management, AI content generation, and PDF export | `8055` |
| **LibreChat** | AI chat interface with MCP integration to query and navigate LMS content | `3080` |

### Features

**Directus LMS:**
- 📚 Course, Module, and Lesson management
- 🤖 AI-powered module and content generation (OpenAI)
- 📄 Automatic PDF lesson plan generation
- 🔍 RAG-based document processing and querying
- ✏️ Custom WYSIWYG editors with math support
- 📊 Quiz and assessment management

**LibreChat Integration:**
- 💬 AI assistant to navigate course content
- 🔗 MCP connection to Directus for real-time data access
- 📖 Retrieve lesson plans, quizzes, and content via natural language
- 🏠 Optional local AI models via Ollama

---

## Project Structure

```
tecktal/
├── tecktal_ai_ethiopia/          # This repository
│   ├── directus/                 # Directus LMS setup
│   │   ├── docker-compose.yml
│   │   ├── .env.example
│   │   ├── snapshot.yaml
│   │   ├── flows-data.sql
│   │   ├── extensions/
│   │   ├── setup.sh             # Linux/Mac setup
│   │   └── setup.ps1            # Windows setup
│   │
│   ├── librechat/               # LibreChat configuration files
│   │   ├── docker-compose.override.yaml
│   │   ├── librechat.yaml
│   │   ├── librechat_agent_instruction.txt
│   │   ├── directus_mcp_instructions.txt
│   │   └── Modelfile            # Ollama model (optional)
│   │
│   └── README.md                # This file
│
└── LibreChat/                   # LibreChat repository (cloned separately)
    ├── docker-compose.yml
    ├── docker-compose.override.yml  # ← Copied from librechat/
    ├── librechat.yaml               # ← Copied from librechat/
    └── .env
```

---

## Prerequisites

- **Docker** and **Docker Compose** installed
- **Git** installed
- **OpenAI API Key** (for AI features)
- **(Optional)** Ollama installed for local AI models

---

## Quick Start

### Step 1: Create Project Folder and Clone Repositories

```bash
mkdir tecktal
cd tecktal

# Clone this repository
git clone https://github.com/YOUR_USERNAME/tecktal_ai_ethiopia.git

# Clone LibreChat (only if you want the AI assistant)
git clone https://github.com/danny-avila/LibreChat.git
```

---

## Part 1: Directus LMS Setup

### Step 1.1: Navigate to Directus Folder

```bash
cd tecktal_ai_ethiopia/directus
```

### Step 1.2: Configure Environment

**Linux/Mac:**
```bash
cp .env.example .env
nano .env  # or use your preferred editor
```

**Windows (PowerShell):**
```powershell
Copy-Item .env.example .env
notepad .env
```

**Edit `.env` and add your OpenAI API key:**
```env
OPENAI_API_KEY=sk-your-openai-api-key-here
```

### Step 1.3: Start Services

```bash
docker compose up -d
```

Wait for all containers to start (check with `docker ps`).

### Step 1.4: Run Setup Script

**Linux/Mac:**
```bash
chmod +x setup.sh
./setup.sh
```

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

### Step 1.5: Verify Installation

Open your browser and go to: **http://localhost:8055**

Login with:
- **Email:** `admin@directus.com`
- **Password:** `admin`

> ⚠️ **Important:** Change the admin password after first login!

### Directus Services

| Service | Port | Description |
|---------|------|-------------|
| Directus | 8055 | Main CMS interface |
| PostgreSQL | 5432 | Database (internal) |
| Qdrant | 6333 | Vector database for RAG |
| RAG Service | 8000 | AI content generation |
| PDF Service | 8001 | HTML to PDF conversion |

---

## Part 2: LibreChat Setup

LibreChat provides an AI assistant that can query your LMS content via MCP (Model Context Protocol).

### Step 2.1: Navigate to LibreChat Folder

```bash
cd tecktal/LibreChat
```

### Step 2.2: Copy Configuration Files

**Linux/Mac:**
```bash
cp ../tecktal_ai_ethiopia/librechat/docker-compose.override.yaml ./docker-compose.override.yml
cp ../tecktal_ai_ethiopia/librechat/librechat.yaml ./librechat.yaml
```

**Windows (PowerShell):**
```powershell
Copy-Item ..\tecktal_ai_ethiopia\librechat\docker-compose.override.yaml .\docker-compose.override.yml
Copy-Item ..\tecktal_ai_ethiopia\librechat\librechat.yaml .\librechat.yaml
```

### Step 2.3: Get Directus API Token

1. Open Directus at **http://localhost:8055**
2. Login as admin
3. Go to **Settings** → **Access Tokens** (or click your avatar → **User Settings**)
4. Create a new **Static Token**
5. Copy the token

### Step 2.4: Configure Environment

**Linux/Mac:**
```bash
cp .env.example .env
nano .env
```

**Windows (PowerShell):**
```powershell
Copy-Item .env.example .env
notepad .env
```

---

### Option A: Setup WITHOUT Local Models (Cloud AI Only)

Add these lines to the **end** of your `.env` file:

```env
# Directus MCP Connection
DIRECTUS_URL=http://host.docker.internal:8055
DIRECTUS_TOKEN=your_directus_static_token_here

# OpenAI (required for cloud models)
OPENAI_API_KEY=sk-your-openai-api-key-here
```

**Use the standard `librechat.yaml`** - no modifications needed.

---

### Option B: Setup WITH Local Models (Ollama)

#### B.1: Install Ollama

Download from: https://ollama.ai/

#### B.2: Create Custom Model

```bash
cd tecktal/tecktal_ai_ethiopia/librechat
ollama create lms-assistant -f Modelfile
```

Verify:
```bash
ollama list
# Should show: lms-assistant
```

#### B.3: Configure Environment

Add these lines to the **end** of your `.env` file:

```env
# Directus MCP Connection
DIRECTUS_URL=http://host.docker.internal:8055
DIRECTUS_TOKEN=your_directus_static_token_here

# OpenAI (optional if using only local models)
OPENAI_API_KEY=sk-your-openai-api-key-here

# Ollama (for local models)
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

#### B.4: Update librechat.yaml for Ollama

Edit `librechat.yaml` in the LibreChat folder and add the Ollama endpoint:

```yaml
version: 1.2.1

cache: true

endpoints:
  agents:
    recursionLimit: 50
    maxRecursionLimit: 100
    disableBuilder: false
    capabilities: ["execute_code", "file_search", "actions", "tools"]

  # ADD THIS SECTION FOR OLLAMA
  custom:
    - name: "Ollama Local"
      apiKey: "ollama"
      baseURL: "http://host.docker.internal:11434/v1"
      models:
        default:
          - "lms-assistant"
        fetch: false
      titleConvo: true
      titleModel: "lms-assistant"
      modelDisplayLabel: "Ollama Local"

mcpServers:
  directus:
    # ... rest of config stays the same
```

---

### Step 2.5: Start LibreChat

```bash
docker compose up -d
```

Wait for all services to start (first run may take a few minutes).

### Step 2.6: Access LibreChat

Open your browser: **http://localhost:3080**

1. Click **Sign Up** to create an account
2. Log in with your new credentials

---

## Part 3: Create the LMS Research Agent

### Step 3.1: Open Agent Builder

1. In LibreChat, click the **model dropdown** at the top
2. Select **Agents** → **+ New Agent**

### Step 3.2: Configure Agent

| Field | Value |
|-------|-------|
| **Name** | LMS Research Assistant |
| **Description** | AI assistant for navigating LMS course content |
| **Model** | `gpt-4-turbo` or `gpt-4o` (NOT gpt-4-0613 - context too small) |

### Step 3.3: Enable MCP Tool

1. Scroll down to **Capabilities** or **Tools**
2. Find and enable **MCP: directus**

### Step 3.4: Add Agent Instructions

Copy the contents of `tecktal_ai_ethiopia/librechat/librechat_agent_instruction.txt` and paste into the **Instructions** field.

> 💡 **Tip:** If you get token limit errors, use the condensed version of the instructions.

### Step 3.5: Save Agent

Click **Save** or **Create Agent**

---

## Part 4: Testing

### Test Directus LMS

1. Go to **http://localhost:8055**
2. Navigate to **Content** → **LMS Courses**
3. Create a course, modules, and lessons
4. Test AI content generation flows

### Test LibreChat Agent

1. Go to **http://localhost:3080**
2. Select your **LMS Research Assistant** agent
3. Try these queries:

```
Show me all available courses
```

```
Show me the modules in [Course Name]
```

```
Get the lesson plan for [Lesson Name]
```

```
Get the quiz for [Module Name]
```

---

## Troubleshooting

### Directus Issues

| Issue | Solution |
|-------|----------|
| Extensions not showing | Run: `docker exec directus-postgres-1 psql -U directus -d directus -c "DELETE FROM directus_extensions WHERE source = 'registry';"` then restart |
| Schema not applied | Re-run setup script |
| Services not starting | Check logs: `docker compose logs -f` |

### LibreChat Issues

| Issue | Solution |
|-------|----------|
| MCP not appearing | Check DIRECTUS_URL uses `host.docker.internal`, not `localhost` |
| Token limit error | Use `gpt-4-turbo` or `gpt-4o` instead of `gpt-4-0613` |
| Config validation error | Check `librechat.yaml` syntax, remove Ollama section if not using it |
| DIRECTUS env not found | Add environment section to `docker-compose.override.yml` |

### Check Container Logs

```bash
# Directus
docker compose logs directus -f

# LibreChat
docker compose logs api -f
```

### Verify Environment Variables

```bash
# Check Directus env in LibreChat
docker exec LibreChat printenv | grep DIRECTUS
```

---

## Updating

### Update Directus Image

```bash
cd tecktal_ai_ethiopia/directus
docker compose pull
docker compose up -d
```

### Update LibreChat

```bash
cd LibreChat
git pull
docker compose pull
docker compose up -d
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                             │
└─────────────────┬───────────────────────────────┬───────────────┘
                  │                               │
                  ▼                               ▼
┌─────────────────────────┐         ┌─────────────────────────────┐
│     Directus LMS        │         │        LibreChat            │
│    localhost:8055       │◄───────▶│      localhost:3080         │
│                         │   MCP   │                             │
│  ┌─────────────────┐    │         │  ┌───────────────────────┐  │
│  │  PostgreSQL     │    │         │  │  MongoDB              │  │
│  │  Qdrant         │    │         │  │  Meilisearch          │  │
│  │  RAG Service    │    │         │  └───────────────────────┘  │
│  │  PDF Service    │    │         │                             │
│  └─────────────────┘    │         │  ┌───────────────────────┐  │
│                         │         │  │  AI Models            │  │
│  ┌─────────────────┐    │         │  │  - OpenAI (cloud)     │  │
│  │  Extensions     │    │         │  │  - Ollama (local)     │  │
│  │  - HTML Editor  │    │         │  └───────────────────────┘  │
│  │  - Math WYSIWYG │    │         │                             │
│  │  - Chat Module  │    │         └─────────────────────────────┘
│  └─────────────────┘    │
└─────────────────────────┘
```

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## License

This project is open source. See LICENSE file for details.

---

## Support

If you encounter issues:
1. Check the Troubleshooting section above
2. Review container logs
3. Open an issue on GitHub

---

## Credits

- [Directus](https://directus.io/) - Headless CMS
- [LibreChat](https://librechat.ai/) - AI Chat Interface
- [Qdrant](https://qdrant.tech/) - Vector Database
- [OpenAI](https://openai.com/) - AI Models
- [Ollama](https://ollama.ai/) - Local AI Models