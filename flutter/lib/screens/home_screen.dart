import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/utente.dart';
import '../theme.dart';
import 'cassa_screen.dart';
import 'storico_screen.dart';
import 'premi_screen.dart';
import 'dashboard_screen.dart';

class _VoceMenu {
  final String titolo;
  final IconData icona;
  final Widget schermata;
  const _VoceMenu({required this.titolo, required this.icona, required this.schermata});
}

List<_VoceMenu> _vociPerRuolo(String ruolo) {
  switch (ruolo) {
    case 'Operatore':
      return [
        _VoceMenu(titolo: 'Cassa', icona: Icons.point_of_sale, schermata: const CassaScreen()),
        _VoceMenu(titolo: 'Storico', icona: Icons.history, schermata: StoricoScreen()),
      ];
    case 'Responsabile':
      return [
        _VoceMenu(titolo: 'Cassa', icona: Icons.point_of_sale, schermata: const CassaScreen()),
        _VoceMenu(titolo: 'Storico', icona: Icons.history, schermata: StoricoScreen()),
        _VoceMenu(titolo: 'Dashboard', icona: Icons.dashboard, schermata: const DashboardScreen()),
      ];
    case 'Amministratore':
      return [
        _VoceMenu(titolo: 'Cassa', icona: Icons.point_of_sale, schermata: const CassaScreen()),
        _VoceMenu(titolo: 'Storico', icona: Icons.history, schermata: StoricoScreen()),
        _VoceMenu(titolo: 'Catalogo Premi', icona: Icons.card_giftcard, schermata: const PremiScreen()),
        _VoceMenu(titolo: 'Dashboard', icona: Icons.dashboard, schermata: const DashboardScreen()),
      ];
    default:
      return const [];
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceSelezionato = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // GlobalKey: permette a Flutter di SPOSTARE il contenuto (da Row a body diretto e viceversa)
  // quando la finestra attraversa gli 800 px, invece di ricrearlo perdendo lo stato delle schermate.
  final _contenutoKey = GlobalKey();
  bool? _eraStretto;

  @override
  Widget build(BuildContext context) {
    final utente = context.watch<AuthProvider>().utente;
    if (utente == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final voci = _vociPerRuolo(utente.ruolo);

    // Contenuto principale (senza Expanded: Expanded si può usare solo dentro Row/Column).
    final corpo = voci.isEmpty
        ? const Center(child: Text('Nessun menu disponibile per questo ruolo.'))
        : IndexedStack(
            key: _contenutoKey,
            index: _indiceSelezionato.clamp(0, voci.length - 1),
            children: voci.asMap().entries.map((e) {
              final schermata = e.value.schermata;
              if (schermata is CassaScreen) {
                return CassaScreen(attiva: e.key == _indiceSelezionato);
              }
              if (schermata is PremiScreen) {
                return PremiScreen(attiva: e.key == _indiceSelezionato);
              }
              if (schermata is StoricoScreen) {
                return StoricoScreen(attiva: e.key == _indiceSelezionato);
              }
              if (schermata is DashboardScreen) {
                return DashboardScreen(attiva: e.key == _indiceSelezionato);
              }
              return schermata;
            }).toList(),
          );

    final menu = _MenuLaterale(
      utente: utente,
      voci: voci,
      indiceSelezionato: _indiceSelezionato,
      onSeleziona: (i) => setState(() => _indiceSelezionato = i),
      onEsci: () => context.read<AuthProvider>().logout(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final largo = constraints.maxWidth > 800;
        if (_eraStretto == false && largo) {
          _scaffoldKey.currentState?.closeDrawer();
        }
        _eraStretto = !largo;
        return Scaffold(
          key: _scaffoldKey,
          appBar: largo
              ? null
              : AppBar(
                  title: const Text(nomeApp),
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                ),
          drawer: largo
              ? null
              : Drawer(
                  // Nel Drawer, dopo la scelta della voce, il Drawer si chiude da solo
                  child: _MenuLaterale(
                    utente: utente,
                    voci: voci,
                    indiceSelezionato: _indiceSelezionato,
                    onSeleziona: (i) {
                      setState(() => _indiceSelezionato = i);
                      Navigator.pop(context);
                    },
                    onEsci: () => context.read<AuthProvider>().logout(),
                  ),
                ),
          body: largo
              ? Row(
                  children: [
                    menu,
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(child: corpo),
                  ],
                )
              : corpo,
        );
      },
    );
  }
}

class _MenuLaterale extends StatelessWidget {
  final Utente utente;
  final List<_VoceMenu> voci;
  final int indiceSelezionato;
  final ValueChanged<int> onSeleziona;
  final VoidCallback onEsci;

  const _MenuLaterale({
    required this.utente,
    required this.voci,
    required this.indiceSelezionato,
    required this.onSeleziona,
    required this.onEsci,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        children: [
          _IntestazioneMenu(utente: utente),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: voci.length,
              itemBuilder: (context, i) {
                final v = voci[i];
                final selezionato = i == indiceSelezionato;
                return ListTile(
                  leading: Icon(v.icona),
                  title: Text(v.titolo),
                  selected: selezionato,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  tileColor: selezionato ? coloreSelezione : null,
                  onTap: () => onSeleziona(i),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _PulsanteEsci(onEsci: onEsci),
        ],
      ),
    );
  }
}

class _IntestazioneMenu extends StatelessWidget {
  final Utente utente;
  const _IntestazioneMenu({required this.utente});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo dell'app (se il file non c'è, mostra un'icona di riserva)
          Image.asset(
            'assets/branding/logo.png',
            width: 56,
            height: 56,
            errorBuilder: (context, error, stack) => const Icon(Icons.card_giftcard, size: 48),
          ),
          const SizedBox(height: 12),
          Text(
            utente.displayName,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            utente.ruolo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PulsanteEsci extends StatelessWidget {
  final VoidCallback onEsci;
  const _PulsanteEsci({required this.onEsci});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: onEsci,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Esci'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

