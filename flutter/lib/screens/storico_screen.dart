import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/cliente.dart';
import '../models/movimento.dart';
import '../theme.dart';

/// Il tema dà ai pulsanti una larghezza minima infinita (pulsante a tutta larghezza).
/// Dentro Row, Wrap, DataTable o finestre di dialogo questo provoca errori di layout
/// ("BoxConstraints forces an infinite width"), quindi qui usiamo una larghezza minima 0.
final ButtonStyle _stileBottone = ElevatedButton.styleFrom(minimumSize: const Size(0, 44));
final ButtonStyle _stileBottoneTabella = ElevatedButton.styleFrom(minimumSize: const Size(0, 36));

/// Schermata Storico Movimenti: filtri, tabella e annullamento (solo Amministratore).
class StoricoScreen extends StatefulWidget {
  /// Quando true la voce Storico è selezionata nel menu: usato per ricaricare
  /// lo storico tornando su questa scheda (IndexedStack conserva lo stato).
  final bool attiva;

  const StoricoScreen({super.key, this.attiva = false});

  @override
  State<StoricoScreen> createState() => _StoricoScreenState();
}

class _StoricoScreenState extends State<StoricoScreen> {
  final _api = ApiService();

  // Controller filtri
  final _codiceC = TextEditingController();
  DateTime? _dataDa;
  DateTime? _dataA;
  final TextEditingController _dataDaC = TextEditingController();
  final TextEditingController _dataAC = TextEditingController();

  // Filtro tipo
  String _tipoSelezionato = 'Tutti';

  // Stato
  List<Movimento> _movimenti = [];
  int _totale = 0;
  String? _errore;
  String? _msgConfermaAnnullamento;
  bool _caricamento = false;
  bool _annullando = false;

  // Controller degli scroll della tabella (la barra orizzontale ne ha bisogno)
  final ScrollController _scrollOriz = ScrollController();
  final ScrollController _scrollVert = ScrollController();

  @override
  void initState() {
    super.initState();
    _caricaStorico();
  }

  @override
  void didUpdateWidget(StoricoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.attiva && widget.attiva) {
      _caricaStorico();
    }
  }

  @override
  void dispose() {
    _codiceC.dispose();
    _dataDaC.dispose();
    _dataAC.dispose();
    _scrollOriz.dispose();
    _scrollVert.dispose();
    super.dispose();
  }

  String? _apiDate(DateTime? d) => d == null ? null : DateFormat('yyyy-MM-dd').format(d);
  String _viewDate(DateTime? d) => d == null ? '' : DateFormat('dd/MM/yyyy').format(d);

  Future<void> _scegliData(bool da) async {
    final iniziale = da ? (_dataDa ?? DateTime.now()) : (_dataA ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: iniziale,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (da) {
        _dataDa = picked;
        _dataDaC.text = _viewDate(picked);
      } else {
        _dataA = picked;
        _dataAC.text = _viewDate(picked);
      }
    });
  }

  void _svuotaData(bool da) {
    setState(() {
      if (da) {
        _dataDa = null;
        _dataDaC.clear();
      } else {
        _dataA = null;
        _dataAC.clear();
      }
    });
  }

  Map<String, dynamic> _bodyStorico(String? clienteId) {
    final body = <String, dynamic>{'azione': 'storico'};
    if (clienteId != null && clienteId.isNotEmpty) body['cliente_id'] = clienteId;
    if (_tipoSelezionato != 'Tutti') {
      body['tipo'] = _tipoSelezionato.toLowerCase();
    }
    final da = _apiDate(_dataDa);
    if (da != null) body['data_da'] = da;
    final a = _apiDate(_dataA);
    if (a != null) body['data_a'] = a;
    return body;
  }
  Future<void> _caricaStorico() async {
    String? clienteId;
    final codice = _codiceC.text.trim();
    if (codice.isNotEmpty) {
      setState(() { _caricamento = true; _errore = null; });
      final r = await _api.post('/ricerca-cliente', {'codice_cliente': codice});
      if (!mounted) return;
      if (r['success'] != true) {
        setState(() {
          _caricamento = false;
          _errore = r['messaggio'] ?? 'Cliente non trovato';
        });
        return;
      }
      final cd = r['cliente'];
      if (cd is! Map<String, dynamic>) {
        setState(() {
          _caricamento = false;
          _errore = 'Cliente non trovato';
        });
        return;
      }
      clienteId = Cliente.fromJson(cd).id;
    }

    if (_dataDa != null && _dataA != null && _dataDa!.isAfter(_dataA!)) {
      setState(() {
        _caricamento = false;
        _errore = 'La data da non può essere successiva alla data a';
      });
      return;
    }

    setState(() { _caricamento = true; _errore = null; });
    final r = await _api.post('/movimenti', _bodyStorico(clienteId));
    if (!mounted) return;
    setState(() { _caricamento = false; });

    if (r['success'] == true) {
      final lista = <Movimento>[];
      final mj = r['movimenti'];
      if (mj is List) {
        for (final m in mj) {
          if (m is Map<String, dynamic>) lista.add(Movimento.fromJson(m));
        }
      }
      setState(() {
        _movimenti = lista;
        _totale = (r['totale'] is int) ? r['totale'] as int : lista.length;
      });
    } else {
      setState(() { _errore = r['messaggio'] ?? 'Errore sconosciuto'; });
    }
  }

  void _azzera() {
    _codiceC.clear();
    _dataDa = null;
    _dataA = null;
    _dataDaC.clear();
    _dataAC.clear();
    _tipoSelezionato = 'Tutti';
    _caricaStorico();
  }

  String _comeIntero(dynamic v) {
    final n = v is num ? v : num.tryParse(v?.toString() ?? '');
    return n == null ? '-' : n.toInt().toString();
  }

  /// Conferma annullamento di un movimento (solo Amministratore).
  Future<void> _annullaMovimento(Movimento m) async {
    final ruolo = context.read<AuthProvider>().utente?.ruolo ?? '';
    final operatore = context.read<AuthProvider>().utente?.username ?? '';
    setState(() { _annullando = true; _errore = null; _msgConfermaAnnullamento = null; });
    try {
      final r = await _api.post('/movimenti', {
        'azione': 'annullamento',
        'ruolo': ruolo,
        'movimento_id': m.id,
        'operatore': operatore,
      });
      if (!mounted) return;
      if (r['success'] == true) {
        final puntiStornati = _comeIntero(r['punti_stornati']);
        final nuovoSaldo = _comeIntero(r['nuovo_saldo_punti']);
        setState(() {
          _msgConfermaAnnullamento =
              'Annullamento effettuato: $puntiStornati punti stornati, nuovo saldo $nuovoSaldo';
          _errore = null;
        });
        await _caricaStorico(); // ricarica mantenendo i filtri
      } else {
        setState(() => _errore = r['messaggio'] ?? 'Errore sconosciuto');
      }
    } finally {
      if (mounted) setState(() => _annullando = false);
    }
  }

  /// Mostra la finestra di conferma prima di annullare un movimento.
  void _mostraDialogConferma(Movimento m) {
    final effetto = m.punti > 0
        ? 'verranno tolti ${m.punti} punti al cliente'
        : 'verranno restituiti ${-m.punti} punti al cliente';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Conferma annullamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${DateFormat('dd/MM/yyyy').format(m.data)}'),
            Text('Tipo: ${m.tipo}'),
            Text('Importo: €${m.importoEuro.toStringAsFixed(2)}'),
            Text('Punti: ${m.puntiConSegno}'),
            const SizedBox(height: 8),
            Text('Confermi l\'annullamento? $effetto.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Indietro'),
          ),
          ElevatedButton(
            style: _stileBottone,
            onPressed: () {
              Navigator.pop(dialogCtx);
              _annullaMovimento(m);
            },
            child: const Text('Conferma annullamento'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ruolo = context.watch<AuthProvider>().utente?.ruolo ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Storico Movimenti')),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filtri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 160,
                              child: TextField(
                                controller: _codiceC,
                                decoration: const InputDecoration(
                                  labelText: 'Codice tessera',
                                  hintText: 'Es. FC-0001',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: DropdownButton<String>(
                                value: _tipoSelezionato,
                                items: const [
                                  DropdownMenuItem(value: 'Tutti', child: Text('Tutti')),
                                  DropdownMenuItem(value: 'Acquisto', child: Text('Acquisto')),
                                  DropdownMenuItem(value: 'Riscatto', child: Text('Riscatto')),
                                  DropdownMenuItem(value: 'Annullamento', child: Text('Annullamento')),
                                ],
                                onChanged: (v) => setState(() => _tipoSelezionato = v ?? 'Tutti'),
                                isExpanded: true,
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: TextField(
                                controller: _dataDaC,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Data da',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                onTap: () => _scegliData(true),
                              ),
                            ),
                            if (_dataDa != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => _svuotaData(true),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            SizedBox(
                              width: 150,
                              child: TextField(
                                controller: _dataAC,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Data a',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                onTap: () => _scegliData(false),
                              ),
                            ),
                            if (_dataA != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => _svuotaData(false),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton(
                              style: _stileBottone,
                              onPressed: _caricamento ? null : _caricaStorico,
                              child: const Text('Cerca'),
                            ),
                            ElevatedButton(
                              style: _stileBottone,
                              onPressed: _caricamento ? null : _azzera,
                              child: const Text('Azzera filtri'),
                            ),
                          ],
                        ),
                        if (_errore != null) ...[
                          const SizedBox(height: 12),
                          Text(_errore!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_caricamento)
                  const Center(child: CircularProgressIndicator()),
                if (!_caricamento && _errore == null)
                  Text('Totale movimenti: $_totale',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_msgConfermaAnnullamento != null) ...[
                  const SizedBox(height: 12),
                  Text(_msgConfermaAnnullamento!,
                      style: const TextStyle(color: colorePuntiPositivi, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 12),
                if (!_caricamento) _tabella(context, ruolo),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _tabella(BuildContext context, String ruolo) {
    final isAmministratore = ruolo == 'Amministratore';
    if (_movimenti.isEmpty) {
      return Center(
        child: Text(_errore ?? 'Nessun movimento trovato con i filtri indicati'),
      );
    }

    // Altezza massima della tabella: oltre questa si scorre dentro la tabella,
    // così la barra orizzontale resta sempre visibile sotto di essa.
    final altezzaMax = (MediaQuery.sizeOf(context).height * 0.55).clamp(260.0, 600.0).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: altezzaMax),
          child: ScrollConfiguration(
            // Permette di trascinare la tabella anche con il mouse (di default solo touch).
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
            ),
            child: Scrollbar(
              controller: _scrollOriz,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollOriz,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: SingleChildScrollView(
                    controller: _scrollVert,
                    child: DataTable(
              columns: [
                const DataColumn(label: Text('Data')),
                const DataColumn(label: Text('Tipo')),
                const DataColumn(label: Text('Importo €')),
                const DataColumn(label: Text('Punti')),
                const DataColumn(label: Text('Operatore')),
                const DataColumn(label: Text('Note')),
                const DataColumn(label: Text('Stato')),
                if (isAmministratore) const DataColumn(label: Text('Azioni')),
              ],
              rows: _movimenti.map((m) {
                return DataRow(cells: [
                  DataCell(Text(DateFormat('dd/MM/yyyy').format(m.data))),
                  DataCell(Text(m.tipo)),
                  DataCell(Text(m.importoEuro.toStringAsFixed(2))),
                  DataCell(
                    Text(
                      m.puntiConSegno,
                      style: TextStyle(
                        color: m.punti >= 0 ? colorePuntiPositivi : colorePuntiNegativi,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(Text(m.operatore ?? '')),
                  DataCell(Text(m.note ?? '')),
                  DataCell(Text(m.annullato ? 'Annullato' : '')),
                  if (isAmministratore)
                    DataCell(
                      m.tipo == 'annullamento' || m.annullato
                          ? const Text('')
                          : ElevatedButton.icon(
                              style: _stileBottoneTabella,
                              onPressed: _annullando ? null : () => _mostraDialogConferma(m),
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Annulla'),
                            ),
                    ),
                ]);
              }).toList(),
                    ), // DataTable
                  ), // SingleChildScrollView verticale
                ), // ConstrainedBox (larghezza minima)
              ), // SingleChildScrollView orizzontale
            ), // Scrollbar
          ), // ScrollConfiguration
        ); // ConstrainedBox (altezza massima)
      },
    );
  }
}
