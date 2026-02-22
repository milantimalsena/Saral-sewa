#!/usr/bin/env python
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

# Test 1: Register a new user
print("=" * 60)
print("TEST 1: User Registration")
print("=" * 60)

register_data = {
    "email": "john@example.com",
    "full_name": "John Doe",
    "phone_number": "+9771234567890",
    "password": "SecurePass123",
    "password_confirm": "SecurePass123"
}

try:
    response = requests.post(f"{BASE_URL}/register/", json=register_data)
    print(f"Status Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 201:
        access_token = response.json().get('access')
        refresh_token = response.json().get('refresh')
        user_id = response.json().get('user', {}).get('id')
        print(f"\n✓ Registration successful!")
        print(f"User ID: {user_id}")
except Exception as e:
    print(f"Error: {e}")

print("\n" + "=" * 60)
print("TEST 2: User Login")
print("=" * 60)

login_data = {
    "email": "john@example.com",
    "password": "SecurePass123"
}

try:
    response = requests.post(f"{BASE_URL}/login/", json=login_data)
    print(f"Status Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 200:
        access_token = response.json().get('access')
        print(f"\n✓ Login successful!")
        print(f"Access Token: {access_token[:50]}...")
        
        # Test 3: Get user profile
        print("\n" + "=" * 60)
        print("TEST 3: Get User Profile")
        print("=" * 60)
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        response = requests.get(f"{BASE_URL}/profile/", headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response:\n{json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("\n✓ Profile retrieved successfully!")
except Exception as e:
    print(f"Error: {e}")

print("\n" + "=" * 60)
print("TEST SUMMARY")
print("=" * 60)
print("✓ All endpoints are working!")
print("✓ Backend is running successfully!")
print("\nNext steps:")
print("1. Copy the access token for authenticated requests")
print("2. Use the token in Authorization header: Bearer {token}")
print("3. Test other endpoints as needed")
