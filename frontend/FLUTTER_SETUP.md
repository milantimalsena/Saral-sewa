# Flutter Frontend Setup Guide - Saral Sewa

Complete setup guide for the Saral Sewa Flutter application with JWT authentication integrated with Django REST backend.

---

## 📋 Prerequisites

- Flutter SDK 3.x or higher (with null safety enabled)
- Dart SDK 2.17 or higher
- Android SDK / iOS SDK (depending on target platforms)
- Running Django backend at `http://127.0.0.1:8000` (see backend guide)

---

## ✅ Project Structure

```
lib/
├── main.dart                          # App entry point with Provider setup
├── theme.dart                         # Theme configuration (Nepal-inspired colors)
├── services/
│   ├── api_service.dart              # HTTP client with token management
│   └── auth_service.dart             # Authentication business logic
├── models/
│   └── user.dart                     # User and AuthResponse data models
├── providers/
│   └── auth_provider.dart            # State management (ChangeNotifier)
├── pages/
│   ├── login_page.dart               # Login screen
│   ├── register_page.dart            # Registration screen
│   ├── home_page.dart                # Dashboard/home screen
│   └── profile_page.dart             # User profile management
├── login_page.dart                   # [Legacy] Can be deleted
├── register_page.dart                # [Legacy] Can be deleted
└── home_page.dart                    # [Legacy] Can be deleted
```

---

## 🚀 Step 1: Add Dependencies

Ensure your `pubspec.yaml` includes these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                        # HTTP client
  flutter_secure_storage: ^9.2.2      # Secure token storage
  provider: ^6.1.1                    # State management
  shared_preferences: ^2.2.2          # Local preferences
```

**Install dependencies:**
```bash
flutter pub get
```

---

## 🔐 Step 2: Configure API Base URL

Edit `lib/services/api_service.dart`:

For **physical device testing:**
```dart
static const String baseUrl = 'http://YOUR_BACKEND_IP:8000/api';
```

For **Android emulator:**
```dart
static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';
```

For **iOS simulator:**
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

---

## 🏗️ Step 3: Understand the Architecture

### ApiService (HTTP Client)
```dart
// Handles all HTTP communication
final apiService = ApiService();

// Automatic token injection in headers
final response = await apiService.get('/profile/');

// Token management
await apiService.saveTokens(accessToken, refreshToken);
await apiService.refreshAccessToken();
```

### AuthService (Business Logic)
```dart
final authService = AuthService(apiService: apiService);

// Registration
final response = await authService.register(
  email: 'user@example.com',
  fullName: 'John Doe',
  password: 'StrongPass123',
  phoneNumber: '+977-XXXXXXXXXX', // Optional
);

// Login
final response = await authService.login(
  email: 'user@example.com',
  password: 'StrongPass123',
);

// Get profile
final user = await authService.getProfile();
```

### AuthProvider (State Management)
```dart
// Access from Consumer or Provider.of
final authProvider = context.read<AuthProvider>();

// Check authentication
if (authProvider.isAuthenticated) {
  // User is logged in
  print('Welcome ${authProvider.user?.fullName}');
}

// Get error messages
print(authProvider.errorMessage); // User-friendly error

// Auth status
print(authProvider.status); // AuthStatus.authenticated/loading/error
```

---

## 📱 Step 4: Update main.dart

The new `main.dart` file includes:
- **Provider setup** with MultiProvider
- **Route configuration** for all pages
- **AuthProvider initialization**
- **Automatic auth status checking** on app startup

Key features:
```dart
void main() async {
  ApiService(); // Initialize singleton
  runApp(const MyApp());
}

// The _RootPage widget automatically:
// 1. Checks if user is already logged in
// 2. Redirects to HomePage if authenticated
// 3. Redirects to LoginPage if not authenticated
```

**No changes needed** in `main.dart` - it's already configured!

---

## 🎨 Step 5: Theme Configuration

The app uses Nepal-inspired colors from `theme.dart`:
- **Primary (Crimson Red):** #DC143C
- **Secondary (Deep Blue):** #003893
- **Background (Off-White):** #F8F6F2

All pages automatically use this theme via MaterialApp.

---

## 🔐 Step 6: Secure Token Storage

Tokens are stored securely using **flutter_secure_storage**:

**iOS:** Keychain
**Android:** Keystore
**Windows/macOS:** Native secure storage

Tokens are **never** stored in SharedPreferences (insecure).

---

## 🌍 Step 7: Configure CORS (Django Backend)

Ensure Django CORS settings allow Flutter:

**backend/saral_sewa/settings.py:**
```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:8000",
    "http://10.0.2.2:8000",  # Android emulator
]
```

---

## 🧪 Step 8: Testing the Integration

### 1. Start Django Backend
```bash
cd backend
python manage.py runserver
```

### 2. Run Flutter App
```bash
flutter run
```

### 3. Test Login Flow
1. Open app → Redirected to LoginPage
2. Click "Sign Up" → Go to RegisterPage
3. Register with test credentials:
   - Email: `test@example.com`
   - Full Name: `Test User`
   - Phone: `+977-1234567890` (optional)
   - Password: `TestPass123!`
4. Successfully registered → HomePage appears
5. Click profile menu → ProfilePage opens
6. View and edit profile
7. Logout → Back to LoginPage

### 4. Test Token Refresh
- Login and leave app open for 15+ minutes
- Make a request (open profile)
- Token should automatically refresh without re-login

---

## 🐛 Troubleshooting

### Issue: Cannot connect to backend

**Solution 1: Check backend is running**
```bash
# Test from terminal
curl http://127.0.0.1:8000/api/login/
# Should return method not allowed (405)
```

**Solution 2: Check base URL**
- Physical device: Use actual IP `http://192.168.x.x:8000/api`
- Android emulator: Use `http://10.0.2.2:8000/api`
- iOS simulator: Use `http://127.0.0.1:8000/api`

**Solution 3: Check CORS configuration**
```bash
curl -H "Origin: http://localhost" http://127.0.0.1:8000/api/login/
# Should have Access-Control-Allow-Origin header
```

### Issue: "Invalid credentials" when login is correct

**Solution:** Check backend admin panel
```bash
# Login to Django admin
http://127.0.0.1:8000/admin/
# Username: admin@saral-sewa.com
# Password: AdminPass123
```

### Issue: Token not persisting after app restart

**Solution:** Nothing to do! The code automatically:
1. Checks for stored token on app startup
2. Verifies token is valid
3. Refreshes if expired

### Issue: Unsupported override of "call"

**Solution:** Make sure pubspec.yaml versions are:
```yaml
provider: ^6.1.1  # NOT 7.0
```

---

## 📚 API Endpoints Reference

All endpoints return JSON. Include token in header:
```
Authorization: Bearer {access_token}
```

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| POST | `/register/` | Create account | No |
| POST | `/login/` | Get JWT tokens | No |
| GET | `/profile/` | Get user data | Yes |
| PATCH | `/profile/update/` | Update profile | Yes |
| POST | `/password-change/` | Change password | Yes |
| POST | `/password-reset-request/` | Request password reset | No |
| POST | `/password-reset/` | Complete password reset | No |
| POST | `/logout/` | Invalidate refresh token | Yes |
| POST | `/token/refresh/` | Get new access token | No* |
| GET | `/verify-token/` | Check token validity | Yes |

*Requires valid refresh token

---

## 🔒 Security Best Practices

✅ **What's already implemented:**
- Tokens stored in secure storage (not SharedPreferences)
- HTTPS ready (configure in production)
- Bearer token authentication
- Automatic token refresh
- Password never sent in plain text
- Validation on all inputs

✅ **Additional steps for production:**

1. **Update base URL to HTTPS**
   ```dart
   static const String baseUrl = 'https://api.saral-sewa.com/api';
   ```

2. **Enable certificate pinning** (advanced)
   ```dart
   // Use http_certificate_pinning package
   ```

3. **Set API timeout**
   ```dart
   // In api_service.dart
   http.TimeoutException after 30 seconds
   ```

4. **Disable debug banner**
   ```dart
   // Already set in main.dart:
   debugShowCheckedModeBanner: false,
   ```

---

## 📦 Deployment Checklist

Before deploying to production:

- [ ] Update base URL to production backend
- [ ] Update theme colors if needed
- [ ] Test all auth flows (login, register, logout, password reset)
- [ ] Test on both Android and iOS
- [ ] Enable certificate pinning
- [ ] Set appropriate timeouts
- [ ] Add privacy policy URL
- [ ] Test with slow/no internet connection
- [ ] Build release APK/IPA
  ```bash
  flutter build apk --release
  flutter build ios --release
  ```

---

## 📞 Support

For issues with:
- **Flutter code:** Check `FLUTTER_INTEGRATION.md`
- **Backend API:** Check `backend/API_TESTING.md`
- **Database:** Check `backend/README.md`

---

## 🎯 Next Steps

1. ✅ Complete this setup
2. 🔄 Test the login/register flow
3. 📱 Add more pages as needed
4. 🚀 Deploy to production

Happy coding! 🚀
