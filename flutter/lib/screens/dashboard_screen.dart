import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

/// Numero JSON (int, double o stringa) come double; 0 se non valido.
double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

/// Un cliente della classifica ("clienti_top" dell'API 06).
class _ClienteTop {
  final int posizione;
  final String nome;
  final String cognome;
  final int saldo;

  const _ClienteTop({
    required this.posizione,
    required this.nome,
    required this.cognome,
    required this.saldo,
  });

  factory _ClienteTop.fromJson(Map<String, dynamic> j) {
    return _ClienteTop(
      posizione: _num(j['posizione']).toInt(),
      nome: (j['nome'] ?? '').toString(),
      cognome: (j['cognome'] ?? '').toString(),
      saldo: _num(j['saldo_punti']).toInt(),
    );
  }

  String get nomeCompleto => '$nome $cognome'.trim();
}

/// Schermata Dashboard (Responsabile e Amministratore): metriche generali del negozio,
/// due grafici e la classifica dei clienti con più punti (API 06).
class DashboardScreen extends StatefulWidget {
  /// Vale true quando la voce Dashboard è quella selezionata nel menu:
  /// serve a ricaricare i dati ogni volta che si apre la scheda.
  final bool attiva;

  const DashboardScreen({super.key, this.attiva = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();

  bool _caricamento = false;
  String? _errore;
  DateTime? _aggiornatoAlle;

  // Dati dell'ultima risposta
  bool _haDati = false;
  int _totaleClienti = 0;
  int _puntiAssegnati = 0;
  int _puntiUtilizzati = 0;
  double _valoreAcquisti = 0;
  int _numeroAcquisti = 0;
  int _numeroRiscatti = 0;
  List<_ClienteTop> _top = [];

  @override
  void initState() {
    super.initState();
    _carica();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.attiva && widget.attiva) {
      _carica();
    }
  }

  /// Legge le metriche dall'API 06 (POST /dashboard con il ruolo dell'utente).
  Future<void> _carica() async {
    final ruolo = context.read<AuthProvider>().utente?.ruolo ?? '';
    if (ruolo != 'Responsabile' && ruolo != 'Amministratore') return;
    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      final r = await _api.post('/dashboard', {'ruolo': ruolo});
      if (!mounted) return;
      if (r['success'] == true) {
        final top = <_ClienteTop>[];
        final tj = r['clienti_top'];
        if (tj is List) {
          for (final c in tj) {
            if (c is Map<String, dynamic>) top.add(_ClienteTop.fromJson(c));
          }
        }
        setState(() {
          _totaleClienti = _num(r['totale_clienti']).toInt();
          _puntiAssegnati = _num(r['punti_assegnati']).toInt();
          _puntiUtilizzati = _num(r['punti_utilizzati']).toInt();
          _valoreAcquisti = _num(r['valore_acquisti']);
          _numeroAcquisti = _num(r['numero_acquisti']).toInt();
          _numeroRiscatti = _num(r['numero_riscatti']).toInt();
          _top = top;
          _haDati = true;
          _aggiornatoAlle = DateTime.now();
        });
      } else {
        setState(() => _errore = (r['messaggio'] ?? 'Errore sconosciuto').toString());
      }
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  String _euro(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} €';

  /// Riquadro con un numero e la sua etichetta.
  Widget _tessera(BuildContext context, IconData icona, String etichetta, String valore) {
    final tema = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icona, color: tema.colorScheme.primary),
              const SizedBox(height: 8),
              Text(valore, style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                etichetta,
                style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Scala "tonda" dell'asse verticale: passo 1, 2 o 5 (per 10, 100, ...) e massimo multiplo del passo,
  /// così le etichette sono 0, 250, 500, 750, 1000 e non numeri strani come 1.020.
  ({double maxY, double step}) _scala(List<double> valori) {
    double m = 0;
    for (final v in valori) {
      if (v > m) m = v;
    }
    if (m <= 0) return (maxY: 10.0, step: 2.0);
    final grezzo = m / 4;
    final grandezza = math.pow(10, (math.log(grezzo) / math.ln10).floor()).toDouble();
    final norm = grezzo / grandezza;
    final bello = norm <= 1 ? 1.0 : (norm <= 2 ? 2.0 : (norm <= 5 ? 5.0 : 10.0));
    final step = bello * grandezza;
    var maxY = (m / step).ceil() * step;
    if (m / maxY > 0.95) maxY += step; // lascia un po' d'aria sopra la barra più alta
    return (maxY: maxY, step: step);
  }

  /// Etichetta sotto una barra.
  Widget _etichettaBarra(String testo) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(testo, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
    );
  }

  FlTitlesData _titoli(List<String> etichette, double step) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, interval: step)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= etichette.length) return const SizedBox.shrink();
            return _etichettaBarra(etichette[i]);
          },
        ),
      ),
    );
  }

  /// Grafico 1: punti assegnati e punti utilizzati.
  Widget _graficoPunti(BuildContext context) {
    final valori = [_puntiAssegnati.toDouble(), _puntiUtilizzati.toDouble()];
    final scala = _scala(valori);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: scala.maxY,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: scala.step),
        borderData: FlBorderData(show: false),
        titlesData: _titoli(const ['Assegnati', 'Utilizzati'], scala.step),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
              toY: valori[0],
              width: 40,
              color: colorePuntiPositivi,
              borderRadius: BorderRadius.circular(6),
            ),
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
              toY: valori[1],
              width: 40,
              color: colorePuntiNegativi,
              borderRadius: BorderRadius.circular(6),
            ),
          ]),
        ],
      ),
    );
  }

  /// Grafico 2: saldo dei clienti con più punti.
  Widget _graficoTop(BuildContext context) {
    final colore = Theme.of(context).colorScheme.primary;
    final valori = _top.map((c) => c.saldo.toDouble()).toList();
    final scala = _scala(valori);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: scala.maxY,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: scala.step),
        borderData: FlBorderData(show: false),
        titlesData: _titoli(_top.map((c) => c.nome).toList(), scala.step),
        barGroups: [
          for (int i = 0; i < _top.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: valori[i],
                width: 28,
                color: colore,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
        ],
      ),
    );
  }

  /// Scheda con titolo e un grafico di altezza fissa.
  Widget _schedaGrafico(BuildContext context, String titolo, Widget grafico) {
    final tema = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titolo, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: grafico),
          ],
        ),
      ),
    );
  }

  /// Classifica testuale dei clienti con più punti.
  Widget _classifica(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clienti con più punti', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_top.isEmpty)
              const Text('Nessun cliente')
            else
              for (final c in _top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 32, child: Text('${c.posizione}', style: tema.textTheme.titleMedium)),
                      Expanded(child: Text(c.nomeCompleto, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 12),
                      Text('${c.saldo} punti', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ruolo = context.watch<AuthProvider>().utente?.ruolo ?? '';

    // Difesa in più: il menu mostra questa voce solo a Responsabile e Amministratore e l'API controlla comunque il ruolo.
    if (ruolo != 'Responsabile' && ruolo != 'Amministratore') {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('Sezione riservata a Responsabile e Amministratore.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Titolo, ora dell'ultimo aggiornamento e pulsante Aggiorna
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Situazione del negozio',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            if (_aggiornatoAlle != null)
                              Text(
                                'Aggiornato alle ${DateFormat('HH:mm').format(_aggiornatoAlle!)}',
                                style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_caricamento) const LinearProgressIndicator(),
                  if (_errore != null) ...[
                    const SizedBox(height: 12),
                    Text(_errore!, style: TextStyle(color: tema.colorScheme.error)),
                  ],
                  if (_haDati) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _tessera(context, Icons.people, 'Clienti', '$_totaleClienti'),
                        _tessera(context, Icons.add_circle_outline, 'Punti assegnati', '$_puntiAssegnati'),
                        _tessera(context, Icons.card_giftcard, 'Punti utilizzati', '$_puntiUtilizzati'),
                        _tessera(context, Icons.euro, 'Valore acquisti', _euro(_valoreAcquisti)),
                        _tessera(context, Icons.shopping_cart_outlined, 'Numero acquisti', '$_numeroAcquisti'),
                        _tessera(context, Icons.redeem, 'Numero riscatti', '$_numeroRiscatti'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _schedaGrafico(context, 'Punti assegnati e utilizzati', _graficoPunti(context)),
                    const SizedBox(height: 16),
                    if (_top.isNotEmpty)
                      _schedaGrafico(context, 'Saldo dei clienti con più punti', _graficoTop(context)),
                    const SizedBox(height: 16),
                    _classifica(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
