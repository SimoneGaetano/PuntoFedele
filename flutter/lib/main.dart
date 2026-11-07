import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const FidelityCardApp(),
    ),
  );
}

class FidelityCardApp extends StatelessWidget {
  const FidelityCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nomeApp,
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

/// Mostra LoginScreen se non c'è utente loggato, HomeScreen altrimenti.
/// login() e logout() in AuthProvider cambiano schermata automaticamente.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.utente != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
