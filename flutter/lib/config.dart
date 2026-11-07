/// Configurazione centrale dell'app.
/// Contiene la base URL delle API n8n (unico punto da modificare).
class Config {
  /// Base URL del webhook n8n. Tutte le chiamate API sono POST con body JSON.
  static const String baseUrl = 'http://localhost:5678/webhook';
}