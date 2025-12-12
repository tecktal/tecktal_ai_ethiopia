# LibreChat + Directus LMS Integration

This guide will help you set up LibreChat as an AI-powered research assistant for the Directus LMS system.

## Overview

LibreChat is configured to connect to Directus via MCP (Model Context Protocol), allowing an AI agent to:
- Navigate course structures (courses → modules → lessons)
- Retrieve lesson plans and PDF links
- Access quizzes and assessments
- Browse lesson content, videos, and assignments

## Prerequisites

- Docker and Docker Compose installed
- Directus LMS running (follow the main project README first)
- Git installed
- (Optional) Ollama installed for local AI models

## Folder Structure

After setup, your folder structure should look like:

```
tecktal/
├── tecktal_ai_ethiopia/          # This repository (Directus LMS)
│   ├── directus/
│   ├── librechat/                # Configuration files (this folder)
│   │   ├── docker-compose.override.yaml
│   │   ├── librechat.yaml
│   │   ├── Modelfile
│   │   ├── librechat_agent_instruction.txt
│   │   ├── directus_mcp_instructions.txt
│   │   └── README.md
│   └── ...
│
└── LibreChat/                    # Official LibreChat repository
    ├── docker-compose.yml
    ├── docker-compose.override.yml  # ← Copied from tecktal_ai_ethiopia/librechat/
    ├── librechat.yaml               # ← Copied from tecktal_ai_ethiopia/librechat/
    └── ...
```

---

## Setup Instructions

### Step 1: Create Project Root Folder

```bash
mkdir tecktal
cd tecktal
```

### Step 2: Clone Both Repositories

```bash
# Clone this project (Directus LMS)
git clone https://github.com/YOUR_USERNAME/tecktal_ai_ethiopia.git

# Clone LibreChat
git clone https://github.com/danny-avila/LibreChat.git
```

### Step 3: Set Up Directus First

Follow the main README in `tecktal_ai_ethiopia/directus/` to get Directus running:

```bash
cd tecktal_ai_ethiopia/directus
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY
docker compose up -d
./setup.sh  # or .\setup.ps1 on Windows
```

Verify Directus is running at `http://localhost:8055`

### Step 4: Get Directus API Token

1. Log into Directus at `http://localhost:8055`
2. Go to **Settings** → **Access Tokens** (or User Settings)
3. Create a new **Static Token** with read permissions
4. Copy the token - you'll need it for LibreChat

### Step 5: Copy Configuration Files to LibreChat

```bash
# From the tecktal root folder
cd tecktal

# Copy the override file
cp tecktal_ai_ethiopia/librechat/docker-compose.override.yaml LibreChat/docker-compose.override.yml

# Copy the LibreChat configuration
cp tecktal_ai_ethiopia/librechat/librechat.yaml LibreChat/librechat.yaml
```

### Step 6: Configure LibreChat Environment

```bash
cd LibreChat

# Copy the example env file
cp .env.example .env
```

Edit the `.env` file and add/modify these variables:

```env
# Directus MCP Connection
DIRECTUS_URL=http://host.docker.internal:8055
DIRECTUS_TOKEN=your_directus_static_token_here

# If using OpenAI
OPENAI_API_KEY=your_openai_key_here

# If using local Ollama models (optional)
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

**Note:** Use `host.docker.internal` to connect from Docker containers to services on your host machine.

### Step 7: Start LibreChat

```bash
cd LibreChat
docker compose up -d
```

Wait for all services to start (this may take a few minutes on first run).

LibreChat will be available at: `http://localhost:3080`

### Step 8: Create LibreChat Account

1. Open `http://localhost:3080`
2. Click **Sign Up** to create an account
3. Log in with your new credentials

---

## Agent Configuration

### Step 9: Create the LMS Research Agent

1. In LibreChat, click the **Model Selector** dropdown
2. Select **Agents** → **+ New Agent**
3. Configure the agent:

| Field | Value |
|-------|-------|
| **Name** | LMS Research Assistant |
| **Description** | AI assistant for navigating LMS course content |
| **Model** | Select your preferred model (GPT-4, Claude, or local Qwen) |
| **Tools** | Enable **MCP: directus** |

### Step 10: Add Agent Instructions

1. In the agent configuration, find the **Instructions** field
2. Copy the entire contents of `librechat_agent_instruction.txt`
3. Paste it into the Instructions field
4. Save the agent

The instructions file is located at:
```
tecktal_ai_ethiopia/librechat/librechat_agent_instruction.txt
```

---

## Directus MCP Configuration

### Step 11: Configure Directus MCP Settings

1. Go to Directus at `http://localhost:8055`
2. Navigate to **Settings** → **MCP** (or Extensions → MCP)
3. Enable MCP if not already enabled
4. Find the **Custom System Prompt** field
5. Copy the contents of `directus_mcp_instructions.txt` and paste it there
6. Save the settings

The MCP instructions file is located at:
```
tecktal_ai_ethiopia/librechat/directus_mcp_instructions.txt
```

---

## Optional: Local AI Model Setup (Ollama)

If you want to use a local AI model instead of cloud APIs:

### Install Ollama

Download and install Ollama from: https://ollama.ai/

### Create Custom Model

```bash
# Navigate to the librechat config folder
cd tecktal/tecktal_ai_ethiopia/librechat

# Create the custom model from Modelfile
ollama create lms-assistant -f Modelfile
```

### Verify Model

```bash
ollama list
# Should show: lms-assistant
```

### Use in LibreChat

When creating your agent, select **Qwen Local** as the model provider (configured in librechat.yaml).

---

## Testing the Integration

### Test 1: Basic Course Query

In LibreChat, select your LMS Research Assistant agent and try:

```
Show me all available courses
```

Expected: List of courses from Directus

### Test 2: Navigate Hierarchy

```
Show me the modules in [Course Name]
```

Expected: Tree structure of modules

### Test 3: Lesson Plan Retrieval

```
Get the lesson plan for [Lesson Name]
```

Expected: HTML content of the lesson plan with PDF link option

### Test 4: Quiz Access

```
Get the quiz for [Module Name]
```

Expected: Formatted quiz questions with answers

---

## Troubleshooting

### Issue: MCP Connection Failed

**Symptoms:** Agent can't retrieve data from Directus

**Solutions:**
1. Verify Directus is running: `docker ps` should show directus container
2. Check the static token is correct in LibreChat `.env`
3. Ensure `DIRECTUS_URL` uses `host.docker.internal` (not `localhost`)
4. Restart LibreChat: `docker compose restart`

### Issue: Permission Errors

**Symptoms:** "You don't have permission to access collection"

**Solutions:**
1. Verify the Directus token has read permissions
2. Check Directus Access Policies include the collections needed
3. The token user should have Administrator role or appropriate permissions

### Issue: Model Not Responding

**Symptoms:** Agent doesn't respond or gives generic answers

**Solutions:**
1. Verify the model is available (check OpenAI API key or Ollama running)
2. Check LibreChat logs: `docker compose logs api`
3. Ensure agent instructions were saved correctly

### Issue: Ollama Connection Failed

**Symptoms:** Local model not available

**Solutions:**
1. Verify Ollama is running: `ollama list`
2. Check firewall allows port 11434
3. Use `host.docker.internal:11434` in configuration

---

## File Reference

| File | Purpose |
|------|---------|
| `docker-compose.override.yaml` | Extends LibreChat Docker config for MCP support |
| `librechat.yaml` | LibreChat configuration with endpoints and MCP servers |
| `Modelfile` | Ollama model definition for local LMS assistant |
| `librechat_agent_instruction.txt` | Agent behavior instructions (paste into agent config) |
| `directus_mcp_instructions.txt` | MCP system prompt (paste into Directus MCP settings) |

---

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│   LibreChat     │────▶│   MCP Server    │────▶│    Directus     │
│   (Frontend)    │     │   (Directus)    │     │    (Backend)    │
│                 │     │                 │     │                 │
│  localhost:3080 │     │                 │     │  localhost:8055 │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                                               │
        │                                               │
        ▼                                               ▼
┌─────────────────┐                           ┌─────────────────┐
│   AI Model      │                           │   PostgreSQL    │
│  (OpenAI/Ollama)│                           │    Database     │
└─────────────────┘                           └─────────────────┘
```

---

## Quick Start Summary

```bash
# 1. Create folder structure
mkdir tecktal && cd tecktal
git clone https://github.com/YOUR_USERNAME/tecktal_ai_ethiopia.git
git clone https://github.com/danny-avila/LibreChat.git

# 2. Setup Directus first
cd tecktal_ai_ethiopia/directus
cp .env.example .env
# Edit .env with your OPENAI_API_KEY
docker compose up -d
./setup.sh

# 3. Copy LibreChat configs
cd ../..
cp tecktal_ai_ethiopia/librechat/docker-compose.override.yaml LibreChat/docker-compose.override.yml
cp tecktal_ai_ethiopia/librechat/librechat.yaml LibreChat/librechat.yaml

# 4. Configure and start LibreChat
cd LibreChat
cp .env.example .env
# Edit .env with DIRECTUS_URL, DIRECTUS_TOKEN, OPENAI_API_KEY
docker compose up -d

# 5. Open LibreChat and create agent
# http://localhost:3080
# Create agent → Add MCP: directus → Paste instructions
```

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review LibreChat logs: `docker compose logs api -f`
3. Review Directus logs: `docker compose logs directus -f`
4. Ensure all environment variables are correctly set

---

## Next Steps

After setup is complete:
1. Explore course content through the agent
2. Test lesson plan retrieval and modifications
3. Try quiz access for different modules
4. Customize agent instructions for your specific needs