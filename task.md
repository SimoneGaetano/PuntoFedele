\# 📋 Roadmap di Progetto: Fidelity Card (IFTS PW2)



> \*\*Descrizione Sintetica:\*\* Sistema Web di gestione carte fedeltà aziendali (accumulo punti 1€ = 1pt, storno e premi) articolato su 3 ruoli (Operatore, Responsabile, Amministratore).

> \*\*Architettura:\*\* Frontend Flutter Web -> Backend API n8n -> DB MongoDB.



\---

\## 🗄️ Fase 1: MongoDB \& Dati di prova

\- \[x] Creare collection `users` con i 3 ruoli (Operatore, Responsabile, Amministratore)

\- \[x] Creare collection `clients` con dati di prova e saldo punti iniziale

\- \[x] Creare collection `purchases\_movements` per lo storico

\- \[x] Creare collection `rewards\_catalog` con i premi (Buono 5€, Tazza, ecc.)



\## ⚡ Fase 2: n8n \& Postman (API)

\- \[x] API Login \& Verifica permessi

\- \[x] API Ricerca cliente \& Visualizzazione saldo/movimenti

\- \[x] API Registrazione acquisto (regola 1€ = 1 punto + aggiornamento saldo)

\- \[x] API Storico movimenti con filtri e annullamento (storno saldo)

\- \[x] API Catalogo premi e riscatto (sottrazione punti)

\- \[x] API Dashboard (metriche e clienti top)



\## 💻 Fase 3: Flutter Web (VS Code)

\- \[x] Setup progetto Flutter e dipendenze (http/dio)

\- \[x] Schermata Login (adattiva per ruolo)

\- \[x] Schermata Cassa / Vendita (ricerca cliente + inserimento spesa)

\- \[x] Schermata Storico Movimenti (`DataTable` + filtri + tasto annulla per Admin)

\- \[x] Schermata Catalogo Premi (riscatto condizionato al saldo)

\- \[x] Schermata Dashboard (metriche e grafici)



\## 📦 Fase 4: Rifiniture, Branding e Consegna

\- \[x] Brainstorming nome app, palette colori e logo (salvare in `/branding`)

\- \[x] Configurazione repository Git / GitHub (opzionale per backup)

\- \[x] Scrivere README con istruzioni di avvio

\- \[x] Fare screenshot e video dimostrativo

\- \[x] Creare e verificare lo ZIP finale strutturato

\- \[x] Caricare lo ZIP sul Drive del corso







