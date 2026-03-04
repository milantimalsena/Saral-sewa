# Saral Sewa Backend - Quick Start Guide

## Prerequisites
- Python 3.8+
- MySQL Server 5.7+
- Git

## Quick Setup (Windows)

### Step 1: Clone Repository
```bash
cd e:\syppp\Saral-sewa\backend
```

### Step 2: Create Virtual Environment
```bash
python -m venv venv
venv\Scripts\activate
```

### Step 3: Install Requirements
```bash
pip install -r requirements.txt
```

### (Optional) Install Dev/Test Requirements
```bash
pip install -r requirements-dev.txt
```

### Step 4: Create MySQL Database
```bash
mysql -u root -p

CREATE DATABASE saral_sewa_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

### Step 5: Create .env File
```bash
copy .env.example .env
```

Edit `.env` with your database credentials and SECRET_KEY

### Step 6: Run Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

### Step 7: Create Superuser
```bash
python manage.py createsuperuser
```

### Step 8: Start Server
```bash
python manage.py runserver
```

Visit:
- Backend: http://127.0.0.1:8000
- Admin: http://127.0.0.1:8000/admin

## Running Tests

This project is configured for `pytest` (including Django integration via `pytest-django`).

```bash
pytest
```

## Testing API Endpoints

### Using cURL

#### Register New User
```bash
curl -X POST http://127.0.0.1:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "full_name": "Test User",
    "phone_number": "+9771234567890",
    "password": "TestPass123",
    "password_confirm": "TestPass123"
  }'
```

#### Login
```bash
curl -X POST http://127.0.0.1:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123"
  }'
```

#### Get Profile (Replace TOKEN with actual access token)
```bash
curl -X GET http://127.0.0.1:8000/api/profile/ \
  -H "Authorization: Bearer TOKEN"
```

#### Logout
```bash
curl -X POST http://127.0.0.1:8000/api/logout/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "REFRESH_TOKEN"
  }'
```

### Using Postman

1. Create new Collection: "Saral Sewa API"
2. Create following requests:

#### Request 1: Register
- Method: POST
- URL: http://127.0.0.1:8000/api/register/
- Body (JSON):
```json
{
    "email": "test@example.com",
    "full_name": "Test User",
    "phone_number": "+9771234567890",
    "password": "TestPass123",
    "password_confirm": "TestPass123"
}
```

#### Request 2: Login
- Method: POST
- URL: http://127.0.0.1:8000/api/login/
- Body (JSON):
```json
{
    "email": "test@example.com",
    "password": "TestPass123"
}
```

#### Request 3: Get Profile
- Method: GET
- URL: http://127.0.0.1:8000/api/profile/
- Headers:
  - Key: Authorization
  - Value: Bearer {access_token_from_login}

## Database Models

### CustomUser
- id (UUID, Primary Key)
- email (Unique, Email)
- full_name (CharField)
- phone_number (CharField, Optional)
- username (CharField, Same as email)
- is_email_verified (Boolean, Default: False)
- is_phone_verified (Boolean, Default: False)
- is_active (Boolean, Default: True)
- created_at (DateTime)
- updated_at (DateTime)
- last_login_ip (IP Address, Optional)

### TokenBlacklist
- id (AutoField)
- token (TextField, Unique)
- user (ForeignKey to CustomUser)
- blacklisted_at (DateTime)
- expires_at (DateTime)

### PasswordResetToken
- id (AutoField)
- user (ForeignKey to CustomUser)
- token (CharField, Unique)
- created_at (DateTime)
- expires_at (DateTime)
- is_used (Boolean, Default: False)

## API Response Status Codes

- 200: OK - Request successful
- 201: Created - Resource created successfully
- 400: Bad Request - Invalid request data
- 401: Unauthorized - Authentication failed or token expired
- 403: Forbidden - Permission denied
- 404: Not Found - Resource not found
- 500: Internal Server Error - Server error

## Security Features

✅ JWT Token Authentication
✅ Custom User Model
✅ Password Hashing (PBKDF2)
✅ Email Uniqueness Validation
✅ Strong Password Requirements
✅ Phone Number Validation
✅ Token Blacklisting
✅ CORS Configuration
✅ Rate Limiting
✅ SQL Injection Protection
✅ CSRF Protection

## Common Issues

### Database Connection Error
```
Check MySQL is running: mysql -u root -p
Check credentials in .env file
```

### Migration Errors
```bash
python manage.py makemigrations authentication
python manage.py migrate
```

### Port Already in Use
```bash
python manage.py runserver 8001
```

## Environment Variables

```env
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

DB_NAME=saral_sewa_db
DB_USER=root
DB_PASSWORD=your_password
DB_HOST=127.0.0.1
DB_PORT=3306

CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

## Admin Panel

Access: http://127.0.0.1:8000/admin/
Login with superuser credentials

Features in Admin:
- User Management
- Token Blacklist Management
- Password Reset Tokens
- View logs and activity

## Next Steps

1. Connect Flutter frontend
2. Add email verification
3. Implement OAuth2
4. Add user roles
5. Deploy to production

## Git Integration

```bash
git init
git add .
git commit -m "Initial Django REST API setup"
git branch -M main
git remote add origin https://github.com/your-repo.git
git push -u origin main
```

## Production Deployment Checklist

- [ ] Generate secure SECRET_KEY
- [ ] Set DEBUG=False
- [ ] Configure allowed hosts
- [ ] Set up SSL/HTTPS
- [ ] Configure email service
- [ ] Set up database backups
- [ ] Configure logging
- [ ] Set up monitoring
- [ ] Configure CORS properly
- [ ] Use environment variables
