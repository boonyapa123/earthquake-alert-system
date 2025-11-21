#!/bin/bash

# Upload Backend to DigitalOcean Server
# This script will create a tar file and upload to server

set -e

SERVER_IP="152.42.248.201"
SERVER_USER="root"
SERVER_PASS="Earthquake123456@Eart"

echo "📦 Preparing backend files for upload..."
echo ""

# Create temporary directory
mkdir -p /tmp/earthquake-backend

# Copy backend files
echo "Copying backend files..."
cp -r backend/* /tmp/earthquake-backend/

# Remove unnecessary files
echo "Cleaning up..."
rm -rf /tmp/earthquake-backend/node_modules
rm -f /tmp/earthquake-backend/.env
rm -f /tmp/earthquake-backend/.env.local

# Create tar file
echo "Creating archive..."
cd /tmp
tar -czf earthquake-backend.tar.gz earthquake-backend/

echo "✅ Archive created: /tmp/earthquake-backend.tar.gz"
echo "📤 Ready to upload to server"
echo ""
echo "Size: $(du -h /tmp/earthquake-backend.tar.gz | cut -f1)"
echo ""
echo "⚠️  Manual upload required:"
echo "1. Open a new terminal"
echo "2. Run: scp /tmp/earthquake-backend.tar.gz root@${SERVER_IP}:~/"
echo "3. Password: ${SERVER_PASS}"
echo ""
echo "Or use this command:"
echo "scp /tmp/earthquake-backend.tar.gz root@${SERVER_IP}:~/"
