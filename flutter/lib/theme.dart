import 'package:flutter/material.dart';

/// Nome dell'applicazione (usato in titoli e intestazioni).
const String nomeApp = 'PuntoFedele';

/// Colore principale dell'app (vedi /branding/PALETTE_E_LOGO.md).
const Color colorePrincipale = Color(0xFF0F766E);

/// Versione scura del colore principale (testi e sfondi scuri).
const Color colorePrincipaleScuro = Color(0xFF134E4A);

/// Colore di accento (la stella del logo, evidenziazioni).
const Color coloreAccento = Color(0xFFF59E0B);

/// Colore punti positivi (accredito).
const Color colorePuntiPositivi = Color(0xFF2E7D32);

/// Colore punti negativi (addebito / annullamento).
const Color colorePuntiNegativi = Color(0xFFC62828);

/// Colore per evidenziare la voce selezionata nel menu laterale (10% opacità del colore principale).
const Color coloreSelezione = Color(0x1A0F766E);

/// Tema dell'applicazione, definito in un unico punto.
ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: colorePrincipale),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorScheme.fromSeed(seedColor: colorePrincipale).surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorePrincipale, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorePrincipale,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
