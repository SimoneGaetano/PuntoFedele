/// Modello Cliente: dati anagrafici e saldo punti.
class Cliente {
  final String? id;
  final String codiceCliente;
  final String nome;
  final String cognome;
  final String email;
  final double saldoPunti;

  const Cliente({
    this.id,
    required this.codiceCliente,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.saldoPunti,
  });

  /// Nome completo da visualizzare.
  String get nomeCompleto => '$nome $cognome'.trim();

  /// Crea un Cliente da una mappa JSON (risposta API /ricerca-cliente).
  /// I campi mancanti usano valori di default sicuri invece di fallire.
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id']?.toString(),
      codiceCliente: (json['codice_cliente'] ?? json['codiceCliente'] ?? '') as String,
      nome: (json['nome'] ?? '') as String,
      cognome: (json['cognome'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      saldoPunti: _parseDouble(json['saldo_punti']),
    );
  }

  /// Parsing sicuro di un numero da JSON (int, double o stringa).
  static double _parseDouble(dynamic valore) {
    if (valore == null) return 0.0;
    if (valore is double) return valore;
    if (valore is int) return valore.toDouble();
    return double.tryParse(valore.toString()) ?? 0.0;
  }
}