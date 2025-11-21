#!/bin/bash

# 🚀 Deploy to DigitalOcean Script
# This script will setup and deploy the earthquake backend to DigitalOcean

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="152.42.248.201"
SERVER_USER="root"
PROJECT_NAME="earthquake_app_new2"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Earthquake API - DigitalOcean Deploy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we have the required files
echo -e "${YELLOW}📋 Checking required files...${NC}"

if [ ! -f "backend/serviceAccountKey.json" ]; then
    echo -e "${RED}❌ Error: backend/serviceAccountKey.json not found${NC}"
    exit 1
fi

if [ ! -f "PRODUCTION_CREDENTIALS.md" ]; then
    echo -e "${RED}❌ Error: PRODUCTION_CREDENTIALS.md not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All required files found${NC}"
echo ""

# Test SSH connection
echo -e "${YELLOW}🔐 Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=5 ${SERVER_USER}@${SERVER_IP} "echo 'Connected'" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ SSH connection successful${NC}"
else
    echo -e "${RED}❌ Cannot connect to server${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Ready to deploy!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Server IP: ${SERVER_IP}"
echo "Project: ${PROJECT_NAME}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update system packages"
echo "2. Install Docker & Docker Compose"
echo "3. Install Nginx"
echo "4. Clone repository"
echo "5. Setup environment variables"
echo "6. Deploy backend"
echo "7. Setup SSL (if domain available)"
echo ""
read -p "Continue with deployment? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo -e "${GREEN}🚀 Starting deployment...${NC}"
echo ""

# This script will be continued in the next steps
echo -e "${YELLOW}⚠️  This is a preparation script${NC}"
echo -e "${YELLOW}Please follow the manual steps in DIGITALOCEAN_PRODUCTION_GUIDE.md${NC}"
