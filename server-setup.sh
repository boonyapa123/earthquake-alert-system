#!/bin/bash
# Server Setup Script for DigitalOcean
# Run this script on the server after installing Docker

set -e

echo "🚀 Earthquake API - Server Setup"
echo "=================================="
echo ""

# Configuration
MONGODB_URI="mongodb+srv://eqnode_admin:RgmdbLBjUA5AdjzG@earthquake-cluster.3qdghto.mongodb.net/eqnode_prod?retryWrites=true&w=majority&appName=earthquake-cluster"
JWT_SECRET=$(openssl rand -base64 32)
FIREBASE_PROJECT_ID="earthquake-api-server"
FIREBASE_BASE64="ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAiZWFydGhxdWFrZS1hcGktc2VydmVyIiwKICAicHJpdmF0ZV9rZXlfaWQiOiAiYzJjMzVjZjRjNDRlNDk0MDI4ZDVhZGEzNWU4NGMwMzcxZTM2NzFlIiwKICAicHJpdmF0ZV9rZXkiOiAiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tXG5NSUlFdkFJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLWXdnZ1NpQWdFQUFvSUJBUUNlN2NzWnNYZkVtMGJNXG5kczJNUENVaG5mWUw3amhDMk85MG9lN3FvbzhyNTU1ZVpmKzN3NWQ3VGsvd1lzUUUrMmUyYm5oMVpJSmQ5ekJyXG5PVHBPR3Vkbkw0YmlUd0ZpTCtUR000K3d4cUNDejhZWU1pZHVsaXMwL21LbzFOVnM3TTlaN1ArUHVEWnRvMmQ3XG45M1pYRzJZdmpKbWM2aU9wMTFmZEN4YUlKdFpZRnFKUnhIN241RUtlcEwzUjJSTU8rREx3Y2pFT1VWUUUrODJvXG50djZCRDhZNXZUVXVrT1ZuTERkc0xHVWU1YzkyWktZNjJ2MVkyTkxBTU9kS1VRYVkvUWUzUCsza0FkbUJnai9iXG5zczkrekdpbFkvaURJT0NaK1ZDcFY2V3RLQ1dHTHlRMDB0Z2dsSllmT3JlOHM4VW4wczBZQkZYV1N4QzltQ1pCXG5EVWNzSGI0UkFnTUJBQUVDZ2dFQUFTcjFCV2gvZlZ4SSt4VURKZ1QxM3FNdUVQakFWUFRxUHdhVzFtWnBCQWtDXG4yZFdZNlQ4MG5tOUZFUHFQejB2UDMzZzh0anVkcGQ0OGJzaEVEbmwrQW0wSDZpTXJtdDZvV1NDOVBUNDY3WkpTdFxuWTJXQWNzeURqeU5Rb3lZVHRxWC9rTTBJRkhTMWdTMGNoRDJkY3U3SWk2QkdTMi93d01Wc1g4dGVZRFFkV25hMlxucFFXSUloZDF6UjJoUlVoZ1hiYW9teU1KS2g5eSt5bHhRYysveTN4N2JsSThxYUpRbFR2cXZjS2syM0FNQkJ6ZVxuMG5WVldhRkRocHFVamdRN1F4Q3pDNGQ5YXNlRk0yTG1EN0lqOE9OaDdMOVpJOVltZTM0UkZjZkg2WktBT3IyL1xuRmZsOS9Cc0ZYdVllUkVOQi9JVFQzdnJlWXBNSnVXL1VYeVo1dy9oZVlRS0JnUURVOFlkUjZuSTRUUHk5TWdnWFxubU9jVDhxYVBhZW9PU0pkRzVGUWZ4Wmhldkp2SCsrRWQ2VFZlMW5CVzQvZGI3RzVNUkNyRC90UWFtbFlTeVBiS1xuYTdNOUZUZjJKZksxZWhpbGJCUkMycjNVL1Erc21oWWhtcW1VWjYrcUpsY3ltVm9EcWVFeFZZQ3FFYnY4VDdlWVxuZzdiYzA5NC92b0ZacGRjZDViWVZoUVlQb1FLQmdRQy9FRmFjUXhHdGc1QlhEbURFcUlYV1hzVlRGSHBhMTJFRFxuc1JROFp0eGFaeVZiRHlYUUNjYWR2NkJJaDd1S3JheGNQMTV0QU1nUktYeUU2YWtIc0lQWUFEUzNwQXM3RWdaalxuTXVCTHRDSFFXM2VidC9ydGI4a3FXS2NkcVJXUWpMRVI4R2ZKNU1JQVhOZTRpQzc1NUYybWFNUzFaNW8rWml1RlxuZmxkbm82SFljUUtCZ0M0UGtKWEhnSzFzK2I1eTlBMG1wZFZLeDN4K0RJTEtjTzZFdFMycU1DdE40T1NCTjFDaFxuQVVwaVdDcHpaUzRkRmo2cEFCY2xKL3daSmtVcDh6Z1YwOCtDcDNnMi9Ta0VJQkNvTURuRjF3b2JNeWpDcThiWlxuRFpWc1dETVYyQWE1NVI2bHdIQkxibWxiTEs2SEQ4K05yaUJXTTl6VitHVEwycHc4OUFYem9Ed0JBb0dBVmtldlxuaFBNNG1XMlBFZkVaTzlXS1Vzc0xPc0JGbko0a1hrRnFEUGk2UzB6RzdyOEJhVmZ3ekMzTDJOVUttTTVpeG1tTFxuWDVmNXdONUdMOU5BbEl0ZWpuMVJVUmlRUmNXWEF0Ym51T2dJV1FubEVubmJvN3RXVVh3bFExeW1zMWNGWXo5M1xuN3hFUmxvNVdrQ3RYWTF0Lyt2VFcxOENJUStOcGhlZ08ybXRuVzlFQ2dZQkU3VjN1QldVY2hIWEVLaW83bnZBWlxuL0h3bkVVRU1kdmxTTG5tNWo5TFZpaW9Kd0oyUXMreUh0QkdIaG9EZi9tdWg3ZmRyVDlTMHVGbTFuVzVOTGpkOVxuUTRsNUlEQUdROVdORFF3dzV1dS9teEhCNFBHeXQ5UVlveThMRDMyejU1OUkzRFJLd08zL1JrcXR1Ty9VQ0VLU1xuMDUrSzZoamhOamJNaTdhWUlKUUJudz09XG4tLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tXG4iLAogICJjbGllbnRfZW1haWwiOiAiZmlyZWJhc2UtYWRtaW5zZGstZmJzdmNAZWFydGhxdWFrZS1hcGktc2VydmVyLmlhbS5nc2VydmljZWFjY291bnQuY29tIiwKICAiY2xpZW50X2lkIjogIjEwNjU1OTQyMTg2MzkyMDM1MTcxMyIsCiAgImF1dGhfdXJpIjogImh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi9hdXRoIiwKICAidG9rZW5fdXJpIjogImh0dHBzOi8vb2F1dGgyLmdvb2dsZWFwaXMuY29tL3Rva2VuIiwKICAiYXV0aF9wcm92aWRlcl94NTA5X2NlcnRfdXJsIjogImh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL29hdXRoMi92MS9jZXJ0cyIsCiAgImNsaWVudF94NTA5X2NlcnRfdXJsIjogImh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL3JvYm90L3YxL21ldGFkYXRhL3g1MDkvZmlyZWJhc2UtYWRtaW5zZGstZmJzdmMlNDBlYXJ0aHF1YWtlLWFwaS1zZXJ2ZXIuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLAogICJ1bml2ZXJzZV9kb21haW4iOiAiZ29vZ2xlYXBpcy5jb20iCn0K"

echo "📦 Step 1: Clone Repository"
cd ~
if [ -d "earthquake_app_new2" ]; then
    echo "Repository already exists, pulling latest..."
    cd earthquake_app_new2
    git pull
else
    echo "Cloning repository..."
    git clone https://github.com/YOUR_USERNAME/earthquake_app_new2.git
    cd earthquake_app_new2
fi

echo ""
echo "📝 Step 2: Create Environment File"
cd backend

cat > .env.production << EOF
# Server Configuration
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database (MongoDB Atlas)
MONGODB_URI=${MONGODB_URI}

# JWT Secret
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRES_IN=7d

# MQTT Configuration
MQTT_BROKER_URL=mqtt://mqtt.uiot.cloud:1883
MQTT_USERNAME=ethernet
MQTT_PASSWORD=ei8jZz87wx
MQTT_CLIENT_ID=eqnode_backend_prod

# CORS
ALLOWED_ORIGINS=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Firebase
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}
FIREBASE_SERVICE_ACCOUNT_BASE64=${FIREBASE_BASE64}
EOF

echo "✅ Environment file created"
echo ""

echo "🐳 Step 3: Create Docker Compose Production File"
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  api:
    build: .
    container_name: eqnode-api-prod
    restart: unless-stopped
    env_file:
      - .env.production
    ports:
      - "3000:3000"
    networks:
      - eqnode-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  eqnode-network:
    driver: bridge
EOF

echo "✅ Docker Compose file created"
echo ""

echo "🔨 Step 4: Build and Run Docker Container"
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

echo ""
echo "⏳ Waiting for container to start..."
sleep 10

echo ""
echo "📊 Step 5: Check Container Status"
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs --tail=50

echo ""
echo "✅ Backend deployed successfully!"
echo ""
echo "🎯 Next steps:"
echo "1. Setup Nginx reverse proxy"
echo "2. Setup firewall"
echo "3. Test API"
echo ""
echo "Test API: curl http://localhost:3000/health"
