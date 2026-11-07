import 'package:intl/intl.dart';

/// Modello Movimento: singolo movimento punti (acquisto, riscatto, annullamento).
class Movimento {
  final String? id;
  final String? clienteId;
  final String tipo;
  final double importoEuro;
  final int punti;
  final DateTime data;
  final String? operatore;
  final String? note;
  final bool annullato;

  const Movimento({
    this.id,
    this.clienteId,
    required this.tipo,
    required this.importoEuro,
    required this.punti,
    required this.data,
    this.operatore,
    this.note,
    this.annullato = false,
  });

  /// Data formattata come gg/mm/aaaa.
  String get dataFormattata => DateFormat('dd/MM/yyyy').format(data);

  /// Punti con segno (+ o -).
  String get puntiConSegno => punti >= 0 ? '+$punti' : '$punti';

  /// Crea un Movimento da una mappa JSON (risposta API /ricerca-cliente).
  /// I campi mancanti usano valori di default sicuri invece di fallire.
  factory Movimento.fromJson(Map<String, dynamic> json) {
    return Movimento(
      id: (json['_id'] ?? json['id'])?.toString(),
      clienteId: json['cliente_id']?.toString(),
      tipo: (json['tipo'] ?? '') as String,
      importoEuro: _parseDouble(json['importo_euro']),
      punti: _parseInt(json['punti']),
      data: _parseDate(json['data']),
      operatore: json['operatore']?.toString(),
      note: json['note']?.toString(),
      annullato: json['annullato'] == true,
    );
  }

  static double _parseDouble(dynamic valore) {
    if (valore == null) return 0.0;
    if (valore is double) return valore;
    if (valore is int) return valore.toDouble();
    return double.tryParse(valore.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic valore) {
    if (valore == null) return 0;
    if (valore is int) return valore;
    if (valore is double) return valore.toInt();
    return int.tryParse(valore.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic valore) {
    if (valore == null) return DateTime.now();
    if (valore is DateTime) return valore;
    try {
      return DateTime.parse(valore.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}