import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// ApiService è l'unico punto di accesso alle API n8n.
/// Espone un unico metodo post() che invia JSON, decodifica la risposta
/// e restituisce sempre una mappa con success/messaggio, mai eccezioni non gestite.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Invia una richiesta POST al percorso [path] con il body [body].
  /// Restituisce una mappa contenente almeno 'success' (bool) e 'messaggio' (String).
  /// In caso di errore di rete, timeout o risposta non valida, restituisce
  /// success: false con un messaggio comprensibile invece di lanciare un'eccezione.
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${Config.baseUrl}$path');

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      // Decodifica la risposta JSON
      final dynamic decoded = jsonDecode(response.body);

      // Se la risposta non è una mappa, consideriamola invalida
      if (decoded is! Map<String, dynamic>) {
        return {
          'success': false,
          'messaggio': 'Risposta del server non valida.',
        };
      }

      // Aggiunge il codice di stato HTTP per comodità
      decoded['statusCode'] = response.statusCode;

      // Se il server ha risposto con success=false, restituiamo il messaggio di errore
      if (decoded['success'] == false) {
        return {
          'success': false,
          'messaggio': decoded['messaggio'] ?? 'Errore sconosciuto dal server.',
          ...decoded,
        };
      }

      // Risposta positiva
      return {
        'success': true,
        ...decoded,
      };
    } on FormatException {
      // Risposta non è JSON valido
      return {
        'success': false,
        'messaggio': 'Risposta del server non valida (JSON non riconosciuto).',
      };
    } on http.ClientException {
      // Errore di rete lato client (es. DNS, connessione rifiutata)
      return {
        'success': false,
        'messaggio': 'Errore di connessione al server. Verifica che n8n sia in esecuzione.',
      };
    } on TimeoutException {
      // Timeout dopo 10 secondi
      return {
        'success': false,
        'messaggio': 'Il server non risponde (timeout 10 secondi).',
      };
    } catch (e) {
      // Qualsiasi altra eccezione imprevista: mai lanciare, sempre restituire messaggio
      return {
        'success': false,
        'messaggio': 'Errore imprevisto durante la chiamata API: $e',
      };
    }
  }
}