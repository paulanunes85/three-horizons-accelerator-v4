#!/usr/bin/env python3
"""Add mkdocs.yml + docs/index.md to each template for TechDocs."""
import os

BASE = "/tmp/golden-paths-push"

templates = {
    "h1-foundation": {
        "basic-cicd": ("Basic CI/CD Pipeline", "GitHub Actions configuration for automated build, test, and deploy workflows."),
        "documentation-site": ("Documentation Site", "MkDocs site with TechDocs integration for the developer portal."),
        "infrastructure-provisioning": ("Infrastructure Provisioning", "Terraform modules for Azure resource deployment."),
        "security-baseline": ("Security Baseline", "Azure Key Vault, OPA policies, and security scanning configuration."),
        "web-application": ("Web Application", "React/Vite web application with TypeScript and Docker."),
    },
    "h2-enhancement": {
        "ado-to-github-migration": ("ADO to GitHub Migration", "Complete toolkit for migrating from Azure DevOps to GitHub."),
        "api-gateway": ("API Gateway", "Express/TypeScript gateway with rate limiting and authentication."),
        "api-microservice": ("API Microservice", "FastAPI microservice with PostgreSQL and Redis."),
        "batch-job": ("Batch Job", "Python batch processing with Kubernetes CronJob scheduling."),
        "data-pipeline": ("Data Pipeline", "Python ETL pipeline with Azure Data services integration."),
        "event-driven-microservice": ("Event-Driven Microservice", "Async Python service with Kafka consumer/producer."),
        "gitops-deployment": ("GitOps Deployment", "Kustomize overlays with ArgoCD Application configuration."),
        "microservice": ("Microservice", "FastAPI production microservice with observability and health checks."),
        "reusable-workflows": ("Reusable Workflows", "GitHub Actions reusable workflows for build, security, and deploy."),
    },
}

for horizon, tmpls in templates.items():
    for name, (title, desc) in tmpls.items():
        mkdocs_path = os.path.join(BASE, horizon, name, "mkdocs.yml")
        docs_dir = os.path.join(BASE, horizon, name, "docs")
        docs_path = os.path.join(docs_dir, "index.md")

        os.makedirs(docs_dir, exist_ok=True)

        with open(mkdocs_path, "w") as f:
            f.write(f"site_name: {title}\nplugins:\n  - techdocs-core\nnav:\n  - Home: index.md\n")

        with open(docs_path, "w") as f:
            f.write(f"# {title}\n\n{desc}\n\n")
            f.write("## Overview\n\nThis Golden Path template provides a pre-configured starting point.\n\n")
            f.write("## Getting Started\n\n")
            f.write("1. Select this template from the developer portal\n")
            f.write("2. Fill in the required parameters\n")
            f.write("3. The scaffolder creates a new repo with all files\n")
            f.write("4. Open in GitHub Codespaces for instant development\n\n")
            f.write("## What You Get\n\n")
            f.write("- Source code skeleton\n")
            f.write("- CI/CD pipeline (GitHub Actions)\n")
            f.write("- Dockerfile for containerization\n")
            f.write("- Kubernetes deployment manifests\n")
            f.write("- Pre-configured Codespace (devcontainer.json)\n")
            f.write("- Catalog registration in the developer portal\n")

        print(f"  {horizon}/{name}: OK")

print("Done")
