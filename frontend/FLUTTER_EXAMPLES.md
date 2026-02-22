# Flutter Integration Examples - Saral Sewa

Practical code examples for integrating authentication into your Flutter application.

---

## 🎯 Example 1: Simple Login Button

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class LoginButtonExample extends StatefulWidget {
  const LoginButtonExample({Key? key}) : super(key: key);

  @override
  State<LoginButtonExample> createState() => _LoginButtonExampleState();
}

class _LoginButtonExampleState extends State<LoginButtonExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (authProvider.errorMessage != null)
              Text(
                authProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () => _handleLogin(context, authProvider),
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin(
      BuildContext context, AuthProvider authProvider) async {
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Navigation handled by _RootPage in main.dart
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
```

---

## 🎯 Example 2: Protected Route with Auth Guard

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class ProtectedPage extends StatelessWidget {
  const ProtectedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is authenticated, show content
        return Scaffold(
          appBar: AppBar(title: const Text('Protected Content')),
          body: Center(
            child: Text('Welcome ${authProvider.user?.fullName}!'),
          ),
        );
      },
    );
  }
}

// Helper widget for inline auth checking
class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? redirectRoute; // Default: '/login'

  const AuthGuard({
    Key? key,
    required this.child,
    this.redirectRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(
              redirectRoute ?? '/login',
            );
          });
          
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return child;
      },
    );
  }
}

// Usage:
// AuthGuard(
//   child: MyProtectedPage(),
//   redirectRoute: '/login',
// )
```

---

## 🎯 Example 3: Display User Profile Data

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Avatar with user's initials
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (user.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                user.phoneNumber!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            // Verification status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatusBadge(
                  label: 'Email',
                  isVerified: user.isEmailVerified,
                ),
                _StatusBadge(
                  label: 'Phone',
                  isVerified: user.isPhoneVerified,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isVerified;

  const _StatusBadge({
    required this.label,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isVerified ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            '$label ${isVerified ? "✓" : "○"}',
            style: TextStyle(
              fontSize: 12,
              color: isVerified ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎯 Example 4: Form with Error Handling

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class RegistrationFormExample extends StatefulWidget {
  const RegistrationFormExample({Key? key}) : super(key: key);

  @override
  State<RegistrationFormExample> createState() =>
      _RegistrationFormExampleState();
}

class _RegistrationFormExampleState extends State<RegistrationFormExample> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Error message banner
              if (authProvider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authProvider.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Full Name Field
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Full name is required';
                  }
                  if (value!.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'email@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Email is required';
                  }
                  if (!value!.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field (Optional)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  hintText: '+977-1234567890',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 8 characters',
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Password is required';
                  }
                  if (value!.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please confirm password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () => _handleSubmit(context, authProvider),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit(
      BuildContext context, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
```

---

## 🎯 Example 5: Logout with Confirmation

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

Future<void> handleLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }
}

// Usage in a menu button:
class LogoutMenuButton extends StatelessWidget {
  const LogoutMenuButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          child: const Text('Logout'),
          onTap: () => handleLogout(context),
        ),
      ],
    );
  }
}
```

---

## 🎯 Example 6: Update Profile with Loading State

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class UpdateProfileForm extends StatefulWidget {
  const UpdateProfileForm({Key? key}) : super(key: key);

  @override
  State<UpdateProfileForm> createState() => _UpdateProfileFormState();
}

class _UpdateProfileFormState extends State<UpdateProfileForm> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user!;
    
    _fullNameController = TextEditingController(text: user.fullName);
    _phoneController = TextEditingController(text: user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () => _handleSave(context, authProvider),
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
            if (authProvider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                authProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _handleSave(
      BuildContext context, AuthProvider authProvider) async {
    final success = await authProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
```

---

## 🎯 Example 7: Change Password Dialog

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

Future<void> showChangePasswordDialog(BuildContext context) async {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Change Password'),
      content: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  obscureText: true,
                ),
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () => _handleChangePassword(
                        context,
                        authProvider,
                        oldPasswordController.text,
                        newPasswordController.text,
                        confirmPasswordController.text,
                      ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            );
          },
        ),
      ],
    ),
  );

  oldPasswordController.dispose();
  newPasswordController.dispose();
  confirmPasswordController.dispose();
}

Future<void> _handleChangePassword(
  BuildContext context,
  AuthProvider authProvider,
  String oldPassword,
  String newPassword,
  String confirmPassword,
) async {
  if (newPassword != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final success = await authProvider.changePassword(
    oldPassword: oldPassword,
    newPassword: newPassword,
  );

  if (success && context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changed successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

---

## 🎯 Example 8: Refresh Profile on Pull-to-Refresh

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class RefreshableProfilePage extends StatefulWidget {
  const RefreshableProfilePage({Key? key}) : super(key: key);

  @override
  State<RefreshableProfilePage> createState() => _RefreshableProfilePageState();
}

class _RefreshableProfilePageState extends State<RefreshableProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return RefreshIndicator(
          onRefresh: () async {
            await authProvider.refreshProfile();
          },
          child: ListView(
            children: [
              if (authProvider.user != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Name: ${authProvider.user!.fullName}'),
                      Text('Email: ${authProvider.user!.email}'),
                    ],
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 🎯 Example 9: Stream-based State Monitoring

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class MonitorAuthState extends StatelessWidget {
  const MonitorAuthState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // React to status changes
        String statusMessage = '';
        
        switch (authProvider.status) {
          case AuthStatus.initial:
            statusMessage = 'Initializing...';
            break;
          case AuthStatus.loading:
            statusMessage = 'Processing...';
            break;
          case AuthStatus.authenticated:
            statusMessage = 'Logged in';
            break;
          case AuthStatus.unauthenticated:
            statusMessage = 'Not logged in';
            break;
          case AuthStatus.error:
            statusMessage = 'Error: ${authProvider.errorMessage}';
            break;
        }

        return Text(statusMessage);
      },
    );
  }
}
```

---

## 📚 Common Patterns

### Pattern 1: Local Widget State + Provider

```dart
// ✅ Use local setState for UI-only state
class SearchableUserList extends StatefulWidget {
  const SearchableUserList({Key? key}) : super(key: key);

  @override
  State<SearchableUserList> createState() => _SearchableUserListState();
}

class _SearchableUserListState extends State<SearchableUserList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
          children: [
            // Local state for search
            TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            // Provider state for user data
            if (authProvider.user != null)
              Text(authProvider.user!.fullName),
          ],
        );
      },
    );
  }
}
```

### Pattern 2: Error Recovery

```dart
// ✅ Auto-recover from token expiration
class SafeApiCall extends StatelessWidget {
  final Future<void> Function(BuildContext) apiCall;

  const SafeApiCall({Key? key, required this.apiCall}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return ElevatedButton(
          onPressed: () async {
            try {
              await apiCall(context);
            } on UnauthorizedException {
              // Token expired, redirect to login
              if (context.mounted) {
                await authProvider.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
          child: const Text('Safe Call'),
        );
      },
    );
  }
}
```

---

## 🚀 Quick Start Checklist

- [x] Update pubspec.yaml with dependencies
- [x] Copy service files (api_service.dart, auth_service.dart)
- [x] Copy model files (user.dart)
- [x] Copy provider files (auth_provider.dart)
- [x] Copy page files (login, register, home, profile)
- [x] Update main.dart with Provider setup
- [x] Test login/register flow
- [x] Test token persistence
- [x] Test logout
- [x] Customize colors/theme if needed
- [x] Deploy to production

---

Happy coding! 🎉
