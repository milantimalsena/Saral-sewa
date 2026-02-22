# API Testing Guide - Saral Sewa Backend

This guide provides examples for testing all API endpoints.

## Test Scenarios

### Scenario 1: Complete User Flow

#### 1. Register New User
```bash
curl -X POST http://127.0.0.1:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "full_name": "John Doe",
    "phone_number": "+9771234567890",
    "password": "SecurePass123",
    "password_confirm": "SecurePass123"
  }'
```

Expected Response (201):
```json
{
    "message": "User registered successfully.",
    "user": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "john@example.com",
        "full_name": "John Doe",
        "phone_number": "+9771234567890",
        "is_email_verified": false,
        "is_phone_verified": false,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "is_active": true
    },
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

#### 2. Login with Registered User
```bash
curl -X POST http://127.0.0.1:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123"
  }'
```

Expected Response (200):
```json
{
    "message": "Login successful.",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "user": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "john@example.com",
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
```bash
curl -X GET http://127.0.0.1:8000/api/profile/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
```

Expected Response (200):
```json
{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john@example.com",
    "full_name": "John Doe",
    "phone_number": "+9771234567890",
    "is_email_verified": false,
    "is_phone_verified": false,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "is_active": true
}
```

#### 4. Update Profile
```bash
curl -X PATCH http://127.0.0.1:8000/api/profile/update/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Jane Doe",
    "phone_number": "+9770987654321"
  }'
```

Expected Response (200):
```json
{
    "message": "Profile updated successfully.",
    "user": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "john@example.com",
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
```bash
curl -X POST http://127.0.0.1:8000/api/password-change/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "old_password": "SecurePass123",
    "new_password": "NewSecurePass456",
    "new_password_confirm": "NewSecurePass456"
  }'
```

Expected Response (200):
```json
{
    "message": "Password changed successfully."
}
```

#### 6. Refresh Token
```bash
curl -X POST http://127.0.0.1:8000/api/token/refresh/ \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }'
```

Expected Response (200):
```json
{
    "access": "new-access-token",
    "refresh": "new-refresh-token"
}
```

#### 7. Verify Token
```bash
curl -X GET http://127.0.0.1:8000/api/verify-token/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
```

Expected Response (200):
```json
{
    "message": "Token is valid.",
    "user": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "john@example.com",
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

#### 8. Logout
```bash
curl -X POST http://127.0.0.1:8000/api/logout/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }'
```

Expected Response (200):
```json
{
    "message": "Logout successful."
}
```

### Error Scenarios

#### Invalid Email on Registration
```bash
curl -X POST http://127.0.0.1:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "invalid-email",
    "full_name": "Test User",
    "password": "SecurePass123",
    "password_confirm": "SecurePass123"
  }'
```

Expected Response (400):
```json
{
    "error": "Registration failed.",
    "details": {
        "email": ["Enter a valid email address."]
    }
}
```

#### Duplicate Email on Registration
```bash
curl -X POST http://127.0.0.1:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "full_name": "Another User",
    "password": "SecurePass123",
    "password_confirm": "SecurePass123"
  }'
```

Expected Response (400):
```json
{
    "error": "Registration failed.",
    "details": {
        "email": ["Email already registered."]
    }
}
```

#### Weak Password
```bash
curl -X POST http://127.0.0.1:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "full_name": "New User",
    "password": "weak",
    "password_confirm": "weak"
  }'
```

Expected Response (400):
```json
{
    "error": "Registration failed.",
    "details": {
        "password": [
            "This password is too short. It must contain at least 8 characters.",
            "Password must contain at least one uppercase letter.",
            "Password must contain at least one digit."
        ]
    }
}
```

#### Mismatched Passwords
```bash
curl -X POST http://127.0.0.1:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "full_name": "New User",
    "password": "SecurePass123",
    "password_confirm": "DifferentPass456"
  }'
```

Expected Response (400):
```json
{
    "error": "Registration failed.",
    "details": {
        "password": ["Passwords do not match."]
    }
}
```

#### Invalid Login Credentials
```bash
curl -X POST http://127.0.0.1:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "WrongPassword123"
  }'
```

Expected Response (401):
```json
{
    "error": "Login failed.",
    "details": {
        "non_field_errors": ["Invalid email or password."]
    }
}
```

#### Unauthorized Access (No Token)
```bash
curl -X GET http://127.0.0.1:8000/api/profile/
```

Expected Response (401):
```json
{
    "detail": "Authentication credentials were not provided."
}
```

#### Invalid Token
```bash
curl -X GET http://127.0.0.1:8000/api/profile/ \
  -H "Authorization: Bearer invalid-token"
```

Expected Response (401):
```json
{
    "detail": "Given token not valid for any token type"
}
```

## Password Reset Flow

#### 1. Request Password Reset
```bash
curl -X POST http://127.0.0.1:8000/api/password-reset-request/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com"
  }'
```

Expected Response (200):
```json
{
    "message": "Password reset link sent to your email.",
    "reset_token": "550e8400-e29b-41d4-a716-446655440000",
    "note": "In production, this token would be sent via email."
}
```

#### 2. Reset Password with Token
```bash
curl -X POST http://127.0.0.1:8000/api/password-reset/ \
  -H "Content-Type: application/json" \
  -d '{
    "token": "550e8400-e29b-41d4-a716-446655440000",
    "new_password": "BrandNewPass789",
    "new_password_confirm": "BrandNewPass789"
  }'
```

Expected Response (200):
```json
{
    "message": "Password reset successfully."
}
```

## Testing with Python Requests

```python
import requests

BASE_URL = "http://127.0.0.1:8000/api"

# Register
response = requests.post(
    f"{BASE_URL}/register/",
    json={
        "email": "test@example.com",
        "full_name": "Test User",
        "password": "TestPass123",
        "password_confirm": "TestPass123"
    }
)
print(response.json())

# Login
response = requests.post(
    f"{BASE_URL}/login/",
    json={
        "email": "test@example.com",
        "password": "TestPass123"
    }
)
data = response.json()
access_token = data['access']

# Get Profile
response = requests.get(
    f"{BASE_URL}/profile/",
    headers={"Authorization": f"Bearer {access_token}"}
)
print(response.json())
```

## Rate Limiting

- Anonymous users: 100 requests/hour
- Authenticated users: 1000 requests/hour

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1642252200
```
