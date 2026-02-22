# Production Deployment Guide - Saral Sewa Backend

## Pre-Deployment Checklist

### Security
- [ ] Generate secure SECRET_KEY
- [ ] Set DEBUG=False
- [ ] Configure ALLOWED_HOSTS with actual domain
- [ ] Enable HTTPS/SSL
- [ ] Configure secure session cookies
- [ ] Set CSRF trusted origins
- [ ] Enable HSTS headers
- [ ] Configure CORS properly

### Database
- [ ] Set up MySQL database on production server
- [ ] Configure database backups
- [ ] Test database replication (if applicable)
- [ ] Create database user with limited permissions
- [ ] Enable database encryption (optional)

### Infrastructure
- [ ] Set up production server
- [ ] Install required system packages
- [ ] Configure firewall rules
- [ ] Set up reverse proxy (Nginx/Apache)
- [ ] Configure to serve on port 80/443
- [ ] Set up SSL certificates (Let's Encrypt)

### Monitoring
- [ ] Set up error tracking (Sentry/DataDog)
- [ ] Configure logging aggregation
- [ ] Set up uptime monitoring
- [ ] Configure alerts
- [ ] Set up performance monitoring

## Generate SECRET_KEY

```bash
# Generate secure secret key
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

## Production Environment Setup

### 1. Server Setup (Ubuntu/Debian)

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y python3 python3-pip python3-venv mysql-server nginx supervisor certbot python3-certbot-nginx

# Create application directories
sudo mkdir -p /var/www/saral-sewa-backend
sudo mkdir -p /var/log/saral-sewa
cd /var/www/saral-sewa-backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt
pip install gunicorn
```

### 2. Production Settings

Create `.env` file with production values:

```env
SECRET_KEY=your-secure-randomly-generated-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

DB_NAME=saral_sewa_db
DB_USER=saral_sewa_user
DB_PASSWORD=very-secure-password
DB_HOST=localhost
DB_PORT=3306

CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com,https://app.yourdomain.com

EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-domain@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

### 3. Database Setup

```bash
# Login to MySQL
mysql -u root -p

# Create database
CREATE DATABASE saral_sewa_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Create user
CREATE USER 'saral_sewa_user'@'localhost' IDENTIFIED BY 'very-secure-password';

# Grant permissions
GRANT ALL PRIVILEGES ON saral_sewa_db.* TO 'saral_sewa_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 4. Django Setup

```bash
cd /var/www/saral-sewa-backend

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser
python manage.py createsuperuser
```

### 5. Gunicorn Configuration

Create `/var/www/saral-sewa-backend/gunicorn_config.py`:

```python
import multiprocessing

bind = "127.0.0.1:8000"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2
max_requests = 1000
max_requests_jitter = 50
access_log = "/var/log/saral-sewa/gunicorn_access.log"
error_log = "/var/log/saral-sewa/gunicorn_error.log"
loglevel = "info"
```

### 6. Supervisor Configuration

Create `/etc/supervisor/conf.d/saral-sewa.conf`:

```ini
[program:saral-sewa]
directory=/var/www/saral-sewa-backend
command=/var/www/saral-sewa-backend/venv/bin/gunicorn \
    --config gunicorn_config.py \
    --chdir /var/www/saral-sewa-backend \
    saral_sewa.wsgi:application

user=www-data
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/saral-sewa/supervisor.log

environment=PATH="/var/www/saral-sewa-backend/venv/bin"
```

### 7. Nginx Configuration

Create `/etc/nginx/sites-available/saral-sewa`:

```nginx
upstream saral_sewa {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    client_max_body_size 20M;

    location / {
        proxy_pass http://saral_sewa;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    location /static/ {
        alias /var/www/saral-sewa-backend/staticfiles/;
    }

    location /media/ {
        alias /var/www/saral-sewa-backend/media/;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/saral-sewa /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

### 8. SSL Certificate Setup

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

This will automatically update Nginx configuration for HTTPS.

### 9. Supervisor Setup

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start saral-sewa
```

Monitor:
```bash
sudo supervisorctl status
sudo tail -f /var/log/saral-sewa/supervisor.log
```

## Post-Deployment

### 1. Verify Installation

```bash
curl https://yourdomain.com/api/register/ -X OPTIONS
```

Should return 200 status code.

### 2. Set Proper Permissions

```bash
sudo chown -R www-data:www-data /var/www/saral-sewa-backend
sudo chmod -R 755 /var/www/saral-sewa-backend
sudo chmod -R 775 /var/www/saral-sewa-backend/media
sudo chmod -R 775 /var/log/saral-sewa
```

### 3. Configure Logging

Create `/var/www/saral-sewa-backend/logs/.gitkeep`:

```bash
mkdir -p /var/www/saral-sewa-backend/logs
touch /var/www/saral-sewa-backend/logs/.gitkeep
```

### 4. Backup Configuration

Create backup script `/usr/local/bin/backup-saral-sewa.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/backup/saral-sewa"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u saral_sewa_user -p'very-secure-password' saral_sewa_db | \
    gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# Backup media files
tar -czf $BACKUP_DIR/media_backup_$DATE.tar.gz \
    /var/www/saral-sewa-backend/media

# Keep only last 30 days of backups
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup completed at $DATE"
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/backup-saral-sewa.sh
```

Add to crontab (daily at 2 AM):
```bash
sudo crontab -e

0 2 * * * /usr/local/bin/backup-saral-sewa.sh
```

### 5. Monitoring Setup

Monitor disk space:
```bash
df -h /var/www/saral-sewa-backend
```

Monitor processes:
```bash
ps aux | grep gunicorn
ps aux | grep supervisor
```

View logs:
```bash
sudo tail -f /var/log/saral-sewa/gunicorn_access.log
sudo tail -f /var/log/saral-sewa/gunicorn_error.log
sudo tail -f /var/log/saral-sewa/supervisor.log
```

## Performance Optimization

### 1. Database Optimization

```sql
-- Add indexes
ALTER TABLE authentication_customuser ADD INDEX idx_email (email);
ALTER TABLE authentication_customuser ADD INDEX idx_is_active (is_active);
ALTER TABLE authentication_customuser ADD INDEX idx_created_at (created_at);
```

### 2. Cache Configuration (Optional)

Install Redis:
```bash
sudo apt-get install redis-server
pip install django-redis
```

Update settings.py:
```python
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://127.0.0.1:6379/1",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        }
    }
}
```

### 3. CDN Configuration

Configure CloudFlare or similar for static content delivery.

## Monitoring & Alerts

### Health Check Endpoint

Add to urls.py:
```python
path('health/', health_check, name='health'),
```

Add to views.py:
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    return Response({'status': 'healthy'}, status=200)
```

Monitor with:
```bash
curl https://yourdomain.com/health/
```

### Error Tracking (Sentry)

```bash
pip install sentry-sdk
```

In settings.py:
```python
import sentry_sdk

sentry_sdk.init(
    dsn="your-sentry-dsn",
    traces_sample_rate=0.1,
    environment="production"
)
```

## Troubleshooting

### Application Won't Start

```bash
# Check supervisor logs
sudo tail -f /var/log/syslog

# Check Django logs
sudo tail -f /var/log/saral-sewa/supervisor.log

# Test Django directly
cd /var/www/saral-sewa-backend
source venv/bin/activate
python manage.py runserver
```

### Database Connection Issues

```bash
# Test connection
mysql -u saral_sewa_user -p'password' saral_sewa_db

# Check MySQL status
sudo service mysql status
```

### Static Files Not Loading

```bash
python manage.py collectstatic --noinput
sudo chown -R www-data:www-data /var/www/saral-sewa-backend/staticfiles
```

### High Memory Usage

- Reduce Gunicorn workers
- Enable database connection pooling
- Configure caching
- Monitor slow queries

## Maintenance

### Weekly
- [ ] Check disk space
- [ ] Review error logs
- [ ] Monitor database size
- [ ] Check backup status

### Monthly
- [ ] Update system packages
- [ ] Update Python packages
- [ ] Review security logs
- [ ] Test backup restoration

### Quarterly
- [ ] Review and optimize slow queries
- [ ] Audit user access
- [ ] Review security policies
- [ ] Update SSL certificates if needed

## Rollback Procedure

```bash
# If deployment fails:
cd /var/www/saral-sewa-backend

# Stop application
sudo supervisorctl stop saral-sewa

# Restore from backup (if using git)
git revert <commit-hash>

# Revert database migrations if needed
python manage.py migrate <app_name> <migration_number>

# Restart application
sudo supervisorctl start saral-sewa
```

## DNS Configuration

Point your domain to server:
```
yourdomain.com  A  your.server.ip.address
www.yourdomain.com  A  your.server.ip.address
```

## Support & Maintenance

For issues or questions:
- Check logs: `/var/log/saral-sewa/`
- Check Django admin: https://yourdomain.com/admin/
- Review API documentation: `/api/docs/` (if Swagger installed)
