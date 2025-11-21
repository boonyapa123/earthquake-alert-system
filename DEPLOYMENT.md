# Deployment Guide - eQNode Production

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.16+
- Android Studio / Xcode
- Firebase CLI
- Domain name and SSL certificates
- Cloud hosting account (AWS/GCP/Azure)

### Environment Setup

1. **Clone and Setup**
   ```bash
   git clone <repository>
   cd earthquake_app_new
   flutter pub get
   ```

2. **Configure Environments**
   - Edit `build_configs/production.env`
   - Update Firebase configurations
   - Set up domain and SSL certificates

3. **Build for Production**
   ```bash
   ./scripts/build_production.sh --confirm-production
   ```

## 🏗️ Infrastructure Setup

### 1. Domain and SSL
```bash
# Example with Let's Encrypt
certbot certonly --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
  -d api.eqnode.com \
  -d mqtt.eqnode.com
```

### 2. Database Setup (PostgreSQL)
```sql
-- Create production database
CREATE DATABASE eqnode_prod;
CREATE USER eqnode_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE eqnode_prod TO eqnode_user;

-- Create tables (run migration scripts)
\i database/migrations/001_create_users.sql
\i database/migrations/002_create_devices.sql
```

### 3. MQTT Broker Setup
```bash
# Install Mosquitto with SSL
sudo apt-get install mosquitto mosquitto-clients

# Configure SSL
sudo nano /etc/mosquitto/mosquitto.conf
```

### 4. Backend API Deployment
```bash
# Deploy to AWS ECS/EKS or similar
docker build -t eqnode-api .
docker tag eqnode-api:latest your-registry/eqnode-api:latest
docker push your-registry/eqnode-api:latest
```

## 📱 Mobile App Configuration

### 1. Update Configuration Files

**lib/config/app_config.dart**
- Verify production URLs
- Ensure security settings are enabled
- Disable debug logging

**android/app/src/main/AndroidManifest.xml**
- Update app name and package
- Configure permissions
- Set network security config

### 2. Firebase Setup

1. **Create Firebase Projects**
   ```bash
   firebase projects:create eqnode-prod
   firebase use eqnode-prod
   ```

2. **Configure FCM**
   ```bash
   firebase apps:create android com.eqnode.app
   firebase apps:sdkconfig android com.eqnode.app
   ```

3. **Update Firebase Config Files**
   - Replace `firebase_configs/firebase_options_prod.dart`
   - Add `google-services.json` to `android/app/`

### 3. Build Production APK

```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BUILD_NUMBER=$(date +%s) \
  --obfuscate \
  --split-debug-info=build/debug-info

# Build App Bundle for Play Store
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BUILD_NUMBER=$(date +%s) \
  --obfuscate \
  --split-debug-info=build/debug-info
```

## 🔐 Security Checklist

### Backend Security
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Configure CORS policies
- [ ] Set up API rate limiting
- [ ] Enable database encryption at rest
- [ ] Configure secure password hashing (bcrypt)
- [ ] Set up JWT token rotation
- [ ] Enable audit logging

### Mobile App Security
- [ ] Remove all debug code and logging
- [ ] Enable code obfuscation
- [ ] Configure certificate pinning
- [ ] Validate all user inputs
- [ ] Secure local storage encryption
- [ ] Remove development credentials

### Infrastructure Security
- [ ] Configure VPC and security groups
- [ ] Set up WAF (Web Application Firewall)
- [ ] Enable DDoS protection
- [ ] Configure backup encryption
- [ ] Set up monitoring and alerting
- [ ] Regular security updates

## 📊 Monitoring Setup

### 1. Application Monitoring
```bash
# Install monitoring agents
npm install --save @datadog/browser-rum
npm install --save @sentry/node
```

### 2. Infrastructure Monitoring
- AWS CloudWatch / Google Cloud Monitoring
- Database performance monitoring
- MQTT broker monitoring
- SSL certificate expiration alerts

### 3. Error Tracking
- Firebase Crashlytics for mobile app
- Sentry for backend API
- Custom error logging and alerting

## 🚀 Deployment Process

### 1. Pre-deployment Checklist
- [ ] All tests passing
- [ ] Security audit completed
- [ ] Performance testing done
- [ ] Backup procedures tested
- [ ] Rollback plan prepared

### 2. Deployment Steps

1. **Backend Deployment**
   ```bash
   # Deploy API server
   kubectl apply -f k8s/production/
   
   # Run database migrations
   npm run migrate:prod
   
   # Verify health checks
   curl https://api.eqnode.com/health
   ```

2. **Mobile App Deployment**
   ```bash
   # Upload to Play Console
   # Upload AAB file and release notes
   
   # Monitor crash reports
   # Check user feedback
   ```

### 3. Post-deployment Verification
- [ ] API endpoints responding correctly
- [ ] MQTT broker accepting connections
- [ ] Push notifications working
- [ ] Database queries performing well
- [ ] SSL certificates valid
- [ ] Monitoring alerts configured

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
The included `.github/workflows/ci-cd.yml` provides:
- Automated testing on PR
- Environment-specific builds
- Artifact storage
- Security scanning

### Manual Deployment Commands
```bash
# Development
./scripts/build_dev.sh

# Staging
./scripts/build_staging.sh

# Production
./scripts/build_production.sh --confirm-production
```

## 📈 Scaling Considerations

### Database Scaling
- Read replicas for query performance
- Connection pooling
- Query optimization
- Data archiving strategy

### API Scaling
- Horizontal pod autoscaling
- Load balancer configuration
- CDN for static assets
- API response caching

### MQTT Scaling
- MQTT broker clustering
- Message persistence
- Connection load balancing
- Topic-based sharding

## 🆘 Troubleshooting

### Common Issues

1. **MQTT Connection Failed**
   ```bash
   # Test MQTT connectivity
   mosquitto_pub -h mqtt.eqnode.com -p 8883 -t test -m "hello" --cafile ca.crt
   ```

2. **API 500 Errors**
   ```bash
   # Check logs
   kubectl logs -f deployment/eqnode-api
   ```

3. **Push Notifications Not Working**
   - Verify FCM server key
   - Check app registration token
   - Validate Firebase project configuration

### Emergency Procedures
- Database backup restoration
- API rollback procedures
- MQTT broker failover
- Emergency contact information

## 📞 Support

### Production Support Contacts
- **Infrastructure**: ops@eqnode.com
- **Application**: dev@eqnode.com
- **Security**: security@eqnode.com

### Monitoring Dashboards
- **Application**: https://monitoring.eqnode.com
- **Infrastructure**: https://infra.eqnode.com
- **Logs**: https://logs.eqnode.com