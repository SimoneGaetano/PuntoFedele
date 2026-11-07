import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/utente.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

/// Schermata di login: campi username/password, pulsante Accedi, gestione errori e caricamento.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService();
  String? _errore;
  bool _caricamento = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _accedi() async {
    setState(() {
      _errore = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Controllo lato app: campi vuoti, nessuna chiamata API
    if (username.isEmpty) {
      setState(() => _errore = 'Inserisci lo username');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errore = 'Inserisci la password');
      return;
    }

    setState(() => _caricamento = true);

    try {
      final risposta = await _api.post('/login', {
        'username': username,
        'password': password,
      });

      if (!mounted) return;

      if (risposta['success'] == true) {
        final utente = Utente.fromJson({
          'username': username,
          'nome': risposta['nome'] ?? '',
          'cognome': risposta['cognome'] ?? '',
          'ruolo': risposta['ruolo'] ?? '',
        });
        context.read<AuthProvider>().login(utente);
        // La schermata cambia da sola tramite Consumer<AuthProvider> in main.dart
      } else {
        setState(() {
          _errore = risposta['messaggio'] ?? 'Errore sconosciuto';
        });
      }
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/branding/logo.png',
                      width: 96,
                      height: 96,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.card_giftcard,
                        size: 64,
                        color: colorePrincipale,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      nomeApp,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorePrincipale,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Inserisci username',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Inserisci password',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errore != null)
                      Text(
                        _errore!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _caricamento ? null : _accedi,
                        child: _caricamento
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Accedi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}