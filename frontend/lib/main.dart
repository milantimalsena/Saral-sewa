import 'package:flutter/material.dart';
import 'theme.dart';
import 'login_page.dart';

void main() {
  runApp(const SaralSewaApp());
}

class SaralSewaApp extends StatelessWidget {
  const SaralSewaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saral Sewa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginPage(),
      // For testing home page directly, use: home: const HomeScreen(),
    );
  }
}
