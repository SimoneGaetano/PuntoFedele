import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/cliente.dart';
import '../theme.dart';

/// Il tema dà ai pulsanti una larghezza minima infinita (pulsante a tutta larghezza).
/// Dentro Row o finestre di dialogo serve una larghezza minima 0, altrimenti
/// Flutter segnala "BoxConstraints forces an infinite width" e la schermata resta bianca.
final ButtonStyle _stileBottone = ElevatedButton.styleFrom(minimumSize: const Size(0, 40));

/// Un premio del catalogo, come restituito dall'API 05 (azione "catalogo").
class _Premio {
  final String id;
  final String nome;
  final String descrizione;
  final int costo;
  final bool riscattabile;
  final int mancanti;

  const _Premio({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.costo,
    required this.riscattabile,
    required this.mancanti,
  });

  factory _Premio.fromJson(Map<String, dynamic> j) {
    return _Premio(
      id: (j['id'] ?? '').toString(),
      nome: (j['nome'] ?? '').toString(),
      descrizione: (j['descrizione'] ?? '').toString(),
      costo: _intero(j['costo_punti']),
      riscattabile: j['riscattabile'] == true,
      mancanti: _intero(j['punti_mancanti']),
    );
  }
}

/// Numero JSON (int, double o stringa) come intero; 0 se non valido.
int _intero(dynamic v) {
  final n = v is num ? v : num.tryParse(v?.toString() ?? '');
  return n == null ? 0 : n.toInt();
}

/// Schermata Catalogo Premi (solo Amministratore): cerca un cliente, mostra i premi
/// con l'indicazione di quelli riscattabili e permette di riscattarli.
class PremiScreen extends StatefulWidget {
  /// Vale true quando la voce Catalogo Premi è quella selezionata nel menu:
  /// serve a ricaricare saldo e premi del cliente già cercato (il saldo può essere cambiato altrove).
  final bool attiva;

  const PremiScreen({super.key, this.attiva = false});
  @override
  State<PremiScreen> createState() => _PremiScreenState();
}

class _PremiScreenState extends State<PremiScreen> {
  final _c = TextEditingController();
  final _api = ApiService();

  Cliente? _cliente;
  List<_Premio> _premi = [];
  String? _errore; // errore della ricerca
  bool _caricamento = false;

  // Stato del riscatto
  bool _riscattando = false;
  String? _esito; // messaggio di conferma
  String? _erroreRiscatto; // errore restituito dall'API

  @override
  void didUpdateWidget(PremiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.attiva && widget.attiva && _cliente != null) {
      _ricaricaCatalogo();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Legge cliente e premi dalla risposta del catalogo. Restituisce true se ok.
  bool _applicaRisposta(Map<String, dynamic> r) {
    final cd = r['cliente'];
    if (cd is! Map<String, dynamic>) return false;
    final lista = <_Premio>[];
    final pj = r['premi'];
    if (pj is List) {
      for (final p in pj) {
        if (p is Map<String, dynamic>) lista.add(_Premio.fromJson(p));
      }
    }
    _cliente = Cliente.fromJson(cd);
    _premi = lista;
    return true;
  }

  /// Nuova ricerca: azzera anche i messaggi del riscatto.
  Future<void> _cerca() async {
    final cod = _c.text.trim();
    _esito = null;
    _erroreRiscatto = null;
    if (cod.isEmpty) {
      setState(() {
        _errore = 'Inserisci il codice tessera';
        _cliente = null;
        _premi = [];
      });
      return;
    }
    final ruolo = context.read<AuthProvider>().utente?.ruolo ?? '';
    setState(() {
      _errore = null;
      _caricamento = true;
      _cliente = null;
      _premi = [];
    });
    try {
      final r = await _api.post('/premi', {
        'azione': 'catalogo',
        'codice_cliente': cod,
        'ruolo': ruolo,
      });
      if (!mounted) return;
      if (r['success'] == true) {
        if (!_applicaRisposta(r)) {
          setState(() => _errore = 'Dati cliente mancanti');
          return;
        }
        setState(() {});
      } else {
        setState(() => _errore = (r['messaggio'] ?? 'Errore sconosciuto').toString());
      }
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  /// Ricarica il catalogo dopo un riscatto SENZA toccare i messaggi di esito/errore.
  Future<void> _ricaricaCatalogo() async {
    final cliente = _cliente;
    if (cliente == null) return;
    final ruolo = context.read<AuthProvider>().utente?.ruolo ?? '';
    final r = await _api.post('/premi', {
      'azione': 'catalogo',
      'codice_cliente': cliente.codiceCliente,
      'ruolo': ruolo,
    });
    if (!mounted) return;
    if (r['success'] == true) {
      setState(() => _applicaRisposta(r));
    }
  }

  /// Chiede conferma e, se confermato, esegue il riscatto.
  Future<void> _confermaRiscatto(_Premio p) async {
    final cliente = _cliente;
    if (cliente == null) return;
    final saldo = cliente.saldoPunti.toInt();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Conferma riscatto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${cliente.nomeCompleto} (${cliente.codiceCliente})'),
            Text('Premio: ${p.nome}'),
            Text('Costo: ${p.costo} punti'),
            const SizedBox(height: 8),
            Text('Saldo attuale: $saldo punti'),
            Text('Saldo dopo il riscatto: ${saldo - p.costo} punti'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Indietro'),
          ),
          ElevatedButton(
            style: _stileBottone,
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Conferma riscatto'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _riscatta(p);
    }
  }

  /// Riscatta il premio (API 05, azione "riscatto").
  Future<void> _riscatta(_Premio p) async {
    final cliente = _cliente;
    if (cliente == null) return;
    final utente = context.read<AuthProvider>().utente;
    final ruolo = utente?.ruolo ?? '';
    final operatore = utente?.username ?? '';
    setState(() {
      _riscattando = true;
      _esito = null;
      _erroreRiscatto = null;
    });
    try {
      final r = await _api.post('/premi', {
        'azione': 'riscatto',
        'codice_cliente': cliente.codiceCliente,
        'ruolo': ruolo,
        'premio_id': p.id,
        'operatore': operatore,
      });
      if (!mounted) return;
      if (r['success'] == true) {
        final usati = _intero(r['punti_usati']);
        final saldo = _intero(r['nuovo_saldo_punti']);
        setState(() {
          _esito = 'Premio riscattato: ${p.nome} (-$usati punti), nuovo saldo $saldo';
        });
        await _ricaricaCatalogo();
      } else {
        setState(() => _erroreRiscatto = (r['messaggio'] ?? 'Errore sconosciuto').toString());
      }
    } finally {
      if (mounted) setState(() => _riscattando = false);
    }
  }

  /// Riga di un premio: nome, descrizione, costo, stato e pulsante Riscatta.
  Widget _cartaPremio(BuildContext context, _Premio p) {
    final tema = Theme.of(context);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (p.descrizione.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.descrizione,
                      style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('Costo: ${p.costo} punti', style: tema.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  p.riscattabile
                      ? const Text(
                          'Riscattabile',
                          style: TextStyle(color: colorePuntiPositivi, fontWeight: FontWeight.bold),
                        )
                      : Text(
                          'Mancano ${p.mancanti} punti',
                          style: TextStyle(color: tema.colorScheme.onSurfaceVariant),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: _stileBottone,
              onPressed: (p.riscattabile && !_riscattando) ? () => _confermaRiscatto(p) : null,
              child: const Text('Riscatta'),
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

    // Difesa in più: il menu mostra questa voce solo all'Amministratore e l'API controlla comunque il ruolo.
    if (ruolo != 'Amministratore') {
      return Scaffold(
        appBar: AppBar(title: const Text('Catalogo Premi')),
        body: const Center(child: Text("Sezione riservata all'Amministratore.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogo Premi')),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Premi e riscatto',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _c,
                    decoration: const InputDecoration(labelText: 'Codice tessera', hintText: 'Es. FC-0001'),
                    onSubmitted: (_) => _caricamento ? null : _cerca(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _caricamento ? null : _cerca,
                      child: _caricamento
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Cerca'),
                    ),
                  ),
                  if (_errore != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errore!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tema.colorScheme.error, fontSize: 14),
                    ),
                  ],
                  if (_cliente != null) ...[
                    const SizedBox(height: 24),
                    // Scheda del cliente con il saldo
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_cliente!.nomeCompleto, style: tema.textTheme.headlineSmall),
                                  const SizedBox(height: 4),
                                  Text('Codice tessera: ${_cliente!.codiceCliente}', style: tema.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                const Text('Saldo punti', style: TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                Text(
                                  '${_cliente!.saldoPunti.toInt()}',
                                  style: tema.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_esito != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _esito!,
                        style: const TextStyle(color: colorePuntiPositivi, fontWeight: FontWeight.bold),
                      ),
                    ],
                    if (_erroreRiscatto != null) ...[
                      const SizedBox(height: 16),
                      Text(_erroreRiscatto!, style: TextStyle(color: tema.colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    Text('Premi disponibili', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_premi.isEmpty)
                      const Text('Nessun premio disponibile')
                    else
                      ..._premi.map((p) => _cartaPremio(context, p)),
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
