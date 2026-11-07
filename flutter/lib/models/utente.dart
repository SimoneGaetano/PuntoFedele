/// Modello Utente: rappresenta l'utente autenticato nell'app.
/// Contiene username, nome, cognome e ruolo (Operatore, Responsabile, Amministratore).
class Utente {
  final String username;
  final String nome;
  final String cognome;
  final String ruolo;

  const Utente({
    required this.username,
    required this.nome,
    required this.cognome,
    required this.ruolo,
  });

  /// Nome completo da visualizzare (es. "Mario Rossi"). Se mancano, usa lo username.
  String get displayName {
    final nomeCompleto = '$nome $cognome'.trim();
    return nomeCompleto.isEmpty ? username : nomeCompleto;
  }

  /// Crea un Utente da una mappa JSON (es. risposta del login).
  /// Se mancano nome/cognome, usa stringa vuota invece di fallire.
  factory Utente.fromJson(Map<String, dynamic> json) {
    return Utente(
      username: json['username'] ?? '',
      nome: json['nome'] ?? '',
      cognome: json['cognome'] ?? '',
      ruolo: json['ruolo'] ?? '',
    );
  }

  /// Converte l'utente in mappa JSON.
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nome': nome,
      'cognome': cognome,
      'ruolo': ruolo,
    };
  }
}