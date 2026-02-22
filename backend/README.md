# Saral Sewa Backend - Authentication System

Production-ready Django REST Framework authentication backend for the Saral Sewa mobile application.

## Installation

### 1. Create Virtual Environment
```bash
python -m venv venv
venv\Scripts\activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Environment Configuration
```bash
cp .env.example .env
```

Edit `.env` and configure:
- SECRET_KEY (generate a secure key)
- Database credentials (MySQL)
- CORS_ALLOWED_ORIGINS
- Email settings (optional)

### 4. Database Setup

#### Create MySQL Database
```bash
mysql -u root -p
CREATE DATABASE saral_sewa_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

#### Run Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

### 5. Create Superuser
```bash
python manage.py createsuperuser
```

### 6. Run Development Server
```bash
python manage.py runserver
```

Server will be available at `http://127.0.0.1:8000`

## API Endpoints

### Authentication Endpoints

#### 1. User Registration
```
POST /api/register/
Content-Type: application/json

{
    "email": "user@example.com",
    "full_name": "John Doe",
    "phone_number": "+9771234567890",
    "password": "SecurePass123",
    "password_confirm": "SecurePass123"
}

Response (201):
{
    "message": "User registered successfully.",
    "user": {
        "id": "uuid",
        "email": "user@example.com",
        "full_name": "John Doe",
        "phone_number": "+9771234567890",
        "is_email_verified": false,
        "is_phone_verified": false,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "is_active": true
    },
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### 2. User Login
```
POST /api/login/
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "SecurePass123"
}

Response (200):
{
    "message": "Login successful.",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "user": {
        "id": "uuid",
        "email": "user@example.com",
        "full_name": "John Doe",
        "phone_number": "+9771234567890",
        "is_email_verified": false,
        "is_phone_verified": false,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "is_active": true
    }
}
```

#### 3. Get User Profile
```
GET /api/profile/
Authorization: Bearer {access_token}

Response (200):
{
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe",
    "phone_number": "+9771234567890",
    "is_email_verified": false,
    "is_phone_verified": false,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "is_active": true
}
```

#### 4. Update User Profile
```
PATCH /api/profile/update/
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "full_name": "Jane Doe",
    "phone_number": "+9770987654321"
}

Response (200):
{
    "message": "Profile updated successfully.",
    "user": {
        "id": "uuid",
        "email": "user@example.com",
        "full_name": "Jane Doe",
        "phone_number": "+9770987654321",
        "is_email_verified": false,
        "is_phone_verified": false,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:35:00Z",
        "is_active": true
    }
}
```

#### 5. Change Password
```
POST /api/password-change/
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "old_password": "SecurePass123",
    "new_password": "NewSecurePass456",
    "new_password_confirm": "NewSecurePass456"
}

Response (200):
{
    "message": "Password changed successfully."
}
```

#### 6. Request Password Reset
```
POST /api/password-reset-request/
Content-Type: application/json

{
    "email": "user@example.com"
}

Response (200):
{
    "message": "Password reset link sent to your email.",
    "reset_token": "uuid-token",
    "note": "In production, this token would be sent via email."
}
```

#### 7. Reset Password
```
POST /api/password-reset/
Content-Type: application/json

{
    "token": "uuid-token",
    "new_password": "NewSecurePass456",
    "new_password_confirm": "NewSecurePass456"
}

Response (200):
{
    "message": "Password reset successfully."
}
```

#### 8. Refresh Access Token
```
POST /api/token/refresh/
Content-Type: application/json

{
    "refresh": "refresh-token-from-login"
}

Response (200):
{
    "access": "new-access-token",
    "refresh": "new-refresh-token"
}
```

#### 9. Logout
```
POST /api/logout/
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "refresh": "refresh-token"
}

Response (200):
{
    "message": "Logout successful."
}
```

#### 10. Verify Token
```
GET /api/verify-token/
Authorization: Bearer {access_token}

Response (200):
{
    "message": "Token is valid.",
    "user": {
        "id": "uuid",
        "email": "user@example.com",
        "full_name": "John Doe",
        "phone_number": "+9771234567890",
        "is_email_verified": false,
        "is_phone_verified": false,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "is_active": true
    }
}
```

## Error Responses

### Registration Error (400)
```json
{
    "error": "Registration failed.",
    "details": {
        "email": ["Email already registered."],
        "password": ["Password must contain at least one uppercase letter."]
    }
}
```

### Login Error (401)
```json
{
    "error": "Login failed.",
    "details": {
        "non_field_errors": ["Invalid email or password."]
    }
}
```

### Unauthorized (401)
```json
{
    "detail": "Authentication credentials were not provided."
}
```

## Security Features

- JWT Token-based authentication
- Custom User model with email as USERNAME_FIELD
- Password hashing using PBKDF2
- Token blacklisting on logout
- Email validation
- Strong password requirements
- Phone number validation
- CORS protection
- SQL injection protection
- CSRF protection (configurable)
- Rate limiting (100 requests/hour for anonymous, 1000/hour for authenticated)

## Project Structure

```
backend/
├── authentication/
│   ├── migrations/
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── serializers.py
│   ├── urls.py
│   └── views.py
├── saral_sewa/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
├── .env.example
├── manage.py
└── requirements.txt
```

## Next Steps

1. Integrate with frontend (Flutter)
2. Add email verification
3. Add SMS notification for phone verification
4. Implement OAuth2 (Google, Facebook)
5. Add user roles and permissions
6. Add API documentation (Swagger/OpenAPI)
7. Deploy to production server
8. Configure SSL/HTTPS
9. Set up monitoring and logging

## Production Deployment

1. Change SECRET_KEY in .env
2. Set DEBUG=False
3. Configure proper database
4. Set ALLOWED_HOSTS
5. Configure CORS properly
6. Set up email backend
7. Use environment variables for sensitive data
8. Enable HTTPS/SSL
9. Set up reverse proxy (Nginx/Apache)
10. Configure WSGI server (Gunicorn/uWSGI)
