import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final clerkService = ClerkService();
  runApp(MyApp(clerkService: clerkService));
}

class MyApp extends StatelessWidget {
  final ClerkService clerkService;
  const MyApp({Key? key, required this.clerkService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(clerkService: clerkService),
        ),
      ],
      child: MaterialApp(
        title: 'Saral Sewa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _RootPage(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const HomePage(),
          '/profile': (context) => const ProfilePage(),
        },
      ),
    );
  }
}

class _RootPage extends StatelessWidget {
  const _RootPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // While the provider is still initialising, show a spinner
        if (authProvider.status == AuthStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}
