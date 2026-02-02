#!/bin/bash
# =============================================================================
# H2 Enhancement - API Microservice - Post Create Script
# =============================================================================

set -e

echo "🚀 Setting up API Microservice: ${{ values.name }}..."

# -----------------------------------------------------------------------------
# Python/FastAPI setup
# -----------------------------------------------------------------------------
echo "🐍 Setting up Python FastAPI environment..."

python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

if [ -f "requirements-dev.txt" ]; then
    pip install -r requirements-dev.txt
fi

# -----------------------------------------------------------------------------
# Pre-commit hooks
# -----------------------------------------------------------------------------
if [ -f ".pre-commit-config.yaml" ]; then
    pip install pre-commit
    pre-commit install
fi

# -----------------------------------------------------------------------------
# Database migrations
# -----------------------------------------------------------------------------
if [ -d "alembic" ] || [ -f "alembic.ini" ]; then
    echo "📦 Database migration framework detected (Alembic)"
    echo "   Run 'alembic upgrade head' after setting up your database"
fi

# -----------------------------------------------------------------------------
# Completion message
# -----------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "✅ API Microservice environment ready!"
echo ""
echo "Quick start:"
echo "  1. Start local services:     docker-compose up -d"
echo "  2. Run database migrations:  alembic upgrade head"
echo "  3. Start the API server:     uvicorn src.main:app --reload"
echo "  4. Open API docs:            http://localhost:8000/docs"
echo ""
echo "Testing:"
echo "  pytest -v --cov=src"
echo ""
echo "Ports:"
echo "  - 8000: FastAPI (OpenAPI docs at /docs)"
echo "  - 5432: PostgreSQL"
echo "  - 6379: Redis"
echo "═══════════════════════════════════════════════════════════════════════"
