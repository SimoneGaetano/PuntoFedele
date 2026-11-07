import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/cliente.dart';
import '../models/movimento.dart';
import '../theme.dart';

class CassaScreen extends StatefulWidget {
  /// Vale true quando la voce Cassa è quella selezionata nel menu:
  /// serve a ricaricare il cliente già cercato (il saldo può essere cambiato altrove).
  final bool attiva;

  const CassaScreen({super.key, this.attiva = false});
  @override
  State<CassaScreen> createState() => _CassaScreenState();
}

class _CassaScreenState extends State<CassaScreen> {
  final _c = TextEditingController();
  final _importoC = TextEditingController();
  final _api = ApiService();
  Cliente? _cliente;
  List<Movimento> _movimenti = [];
  String? _errore;
  bool _caricamento = false;

  // Stato del form "Registra acquisto"
  bool _registrando = false;
  String? _esito;      // messaggio di conferma
  String? _erroreAcquisto; // errore di validazione o API

  @override
  void didUpdateWidget(CassaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Quando si torna sulla scheda Cassa con un cliente già cercato, ne aggiorna saldo e movimenti.
    if (!oldWidget.attiva && widget.attiva && _cliente != null) {
      _ricaricaCliente();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _importoC.dispose();
    super.dispose();
  }
  // ... il resto del file resta uguale
  /// Importo digitato: accetta punto o virgola ("12,50" = 12.5). null se non è un numero.
  double? _importoDigitato() {
    final testo = _importoC.text.trim().replaceAll(',', '.');
    return double.tryParse(testo);
  }

  /// Punti dell'anteprima: parte intera dell'importo (1 € = 1 punto, decimali scartati).
  int _puntiAnteprima() {
    final importo = _importoDigitato();
    if (importo == null || importo <= 0) return 0;
    return importo.floor();
  }

  /// Legge cliente e movimenti dalla risposta di /ricerca-cliente. Restituisce true se ok.
  bool _applicaRisposta(Map<String, dynamic> r) {
    final cd = r['cliente'];
    if (cd is! Map<String, dynamic>) return false;
    final lm = <Movimento>[];
    final mj = r['movimenti'];
    if (mj is List) {
      for (final m in mj) {
        if (m is Map<String, dynamic>) lm.add(Movimento.fromJson(m));
      }
    }
    _cliente = Cliente.fromJson(cd);
    _movimenti = lm;
    return true;
  }

  /// Nuova ricerca: azzera anche il form dell'acquisto.
  Future<void> _cerca() async {
    final cod = _c.text.trim();
    // Azzero il form acquisto solo qui (nuova ricerca)
    _importoC.clear();
    _esito = null;
    _erroreAcquisto = null;
    if (cod.isEmpty) {
      setState(() { _errore = 'Inserisci il codice tessera'; _cliente = null; _movimenti = []; });
      return;
    }
    setState(() { _errore = null; _caricamento = true; _cliente = null; _movimenti = []; });
    try {
      final r = await _api.post('/ricerca-cliente', {'codice_cliente': cod});
      if (!mounted) return;
      if (r['success'] == true) {
        if (!_applicaRisposta(r)) {
          setState(() => _errore = 'Dati cliente mancanti');
          return;
        }
        setState(() {});
      } else {
        setState(() { _errore = r['messaggio'] ?? 'Errore sconosciuto'; _cliente = null; _movimenti = []; });
      }
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  /// Ricarica cliente e movimenti dopo un acquisto, SENZA toccare importo, esito ed errore.
  Future<void> _ricaricaCliente() async {
    final cliente = _cliente;
    if (cliente == null) return;
    final r = await _api.post('/ricerca-cliente', {'codice_cliente': cliente.codiceCliente});
    if (!mounted) return;
    if (r['success'] == true) {
      setState(() => _applicaRisposta(r));
    }
  }

  /// Registra l'acquisto (API 03).
  Future<void> _registraAcquisto() async {
    final cliente = _cliente;
    if (cliente == null) return;
    final importo = _importoDigitato();
    if (importo == null || importo <= 0) {
      setState(() { _erroreAcquisto = 'Inserisci un importo maggiore di 0'; _esito = null; });
      return;
    }
    final operatore = context.read<AuthProvider>().utente?.username ?? '';
    setState(() { _registrando = true; _erroreAcquisto = null; _esito = null; });
    try {
      final r = await _api.post('/registra-acquisto', {
        'codice_cliente': cliente.codiceCliente,
        'importo_euro': importo,
        'operatore': operatore,
      });
      if (!mounted) return;
      if (r['success'] == true) {
        final punti = _comeIntero(r['punti_aggiunti']);
        final saldo = _comeIntero(r['nuovo_saldo']);
        setState(() {
          _esito = 'Acquisto registrato: +$punti punti, nuovo saldo $saldo';
          _importoC.clear();
        });
        await _ricaricaCliente();
      } else {
        setState(() => _erroreAcquisto = r['messaggio'] ?? 'Errore sconosciuto');
      }
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  /// Numero JSON (int, double o stringa) mostrato come intero.
  String _comeIntero(dynamic v) {
    final n = v is num ? v : num.tryParse(v?.toString() ?? '');
    return n == null ? '-' : n.toInt().toString();
  }
  /// Form sotto la card del cliente.
  Widget _formAcquisto(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registra acquisto', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _importoC,
              enabled: !_registrando,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Importo (€)', hintText: 'Es. 12,50'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _registrando ? null : _registraAcquisto(),
            ),
            const SizedBox(height: 8),
            Text('Punti che verranno assegnati: ${_puntiAnteprima()}', style: tema.textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _registrando ? null : _registraAcquisto,
                child: _registrando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Registra acquisto'),
              ),
            ),
            if (_erroreAcquisto != null) ...[
              const SizedBox(height: 12),
              Text(_erroreAcquisto!, style: TextStyle(color: tema.colorScheme.error)),
            ],
            if (_esito != null) ...[
              const SizedBox(height: 12),
              Text(_esito!, style: const TextStyle(color: colorePuntiPositivi, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cassa / Vendita')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ricerca cliente', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(controller: _c, decoration: const InputDecoration(labelText: 'Codice tessera', hintText: 'Es. FC-0001'), onSubmitted: (_) => _cerca()),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _caricamento ? null : _cerca, child: _caricamento ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Cerca'))),
                  const SizedBox(height: 24),
                  if (_errore != null) Text(_errore!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14), textAlign: TextAlign.center),
                  if (_cliente != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_cliente!.nomeCompleto, style: Theme.of(context).textTheme.headlineSmall),
                                      const SizedBox(height: 4),
                                      Text('Codice tessera: ${_cliente!.codiceCliente}', style: Theme.of(context).textTheme.bodyMedium),
                                      const SizedBox(height: 4),
                                      Text('Email: ${_cliente!.email}', style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    const Text('Saldo punti', style: TextStyle(fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Text('${_cliente!.saldoPunti.toInt()}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text('Ultimi movimenti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            if (_movimenti.isEmpty)
                              const Text('Nessun movimento')
                            else
                              ..._movimenti.map(
                                (m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    m.dataFormattata,
                                                    softWrap: false,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(
                                                    m.tipo,
                                                    softWrap: false,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            m.puntiConSegno,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: m.punti >= 0 ? colorePuntiPositivi : colorePuntiNegativi,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (m.note != null && m.note!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            m.note!,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formAcquisto(context),
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
