import 'package:flutter/foundation.dart';
import '../models/utente.dart';

/// Provider che gestisce lo stato di autentica dell'utente.
/// Dopo il login memorizza l'utente loggato e lo rende disponibile a tutte le schermate.
class AuthProvider extends ChangeNotifier {
  Utente? _utente;

  /// L'utente attualmente loggato (null se non è stato effettuato il login).
  Utente? get utente => _utente;

  /// Restituisce true se c'è un utente loggato.
  bool get isLoggedIn => _utente != null;

  /// Memorizza l'utente dopo un login avvenuto con successo.
  void login(Utente utente) {
    _utente = utente;
    notifyListeners();
  }

  /// Effettua il logout: rimuove l'utente memorizzato.
  void logout() {
    _utente = null;
    notifyListeners();
  }
}