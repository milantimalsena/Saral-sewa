# Saral Sewa

Saral Sewa is a full-stack mobile application built with **Flutter (Android)** and a **Django REST Framework** backend that provides **JWT-based authentication** (register, login, profile, password reset/change, logout).

## Repository Structure

- `frontend/` — Flutter application (UI)
- `backend/` — Django REST Framework API (authentication system)
- `lib/`, `pubspec.yaml` — Flutter project files (if you are using the root Flutter project)
- `IMPLEMENTATION_SUMMARY.md` — Detailed implementation notes and delivered features

> Note: This repo contains both `frontend/` and also Flutter files at the repository root. If you are actively using `frontend/` as the main app, treat the root Flutter files as legacy/extra. If you are using the root Flutter app, you may not need `frontend/`.

---

## Features

### Mobile (Flutter)
- Login / Register UI
- Home dashboard
- Profile view + update
- Change password
- Secure token storage (`flutter_secure_storage`)
- Provider-based state management

### Backend (Django REST Framework)
- JWT authentication (access + refresh tokens)
- Token refresh + logout token blacklisting
- Profile endpoints
- Password change + reset flows
- CORS configuration for Flutter integration

---

## Download / Install (Android APK)

You can install the app from **GitHub Releases**:

1. Go to the repo **Releases** page
2. Download the latest `app-release.apk`
3. On your Android phone, allow **Install unknown apps** when prompted
4. Tap the APK and install

> If you get “App not installed”, uninstall any older version first and try again.

---

## Run the Flutter App (Development)

### Prerequisites
- Flutter SDK installed
- Android Studio (or VS Code) + Android emulator/device

### Setup
```bash
cd frontend
flutter pub get
flutter run
