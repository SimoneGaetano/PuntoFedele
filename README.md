# PuntoFedele – Sistema di raccolta punti per un negozio

Project Work IFTS · Flutter Web · n8n · MongoDB
Autore: Simone Gaetano Amato

## Descrizione

**PuntoFedele** è un'applicazione web per la gestione di una *fidelity card* in un negozio. Il cliente accumula **1 punto per ogni euro speso** (decimali scartati) e può scambiare i punti con premi del catalogo.

Funzioni principali:

* login con tre livelli di accesso (Operatore, Responsabile, Amministratore);
* **Cassa**: ricerca del cliente per codice tessera, saldo punti, registrazione di un acquisto;
* **Storico movimenti**: tabella con filtri (cliente, tipo, intervallo di date) e **annullamento** di un movimento con storno dei punti (solo Amministratore);
* **Catalogo premi** e **riscatto** (solo Amministratore), con controllo del saldo;
* **Dashboard** con indicatori, grafici e classifica clienti (Responsabile e Amministratore).

Architettura:

```
Flutter Web  ──POST JSON──▶  n8n (6 webhook)  ──▶  MongoDB (database fidelity_db)
```

Flutter comunica con MongoDB **esclusivamente tramite le API n8n**. I permessi sono controllati sia nell'app (menu per ruolo) sia nelle API (risposta 403).

## Contenuto dello ZIP

| Cartella | Contenuto |
|---|---|
| `flutter/` | progetto Flutter Web (codice, asset, configurazioni) |
| `n8n/` | i 6 workflow esportati in JSON, `README_n8n.md` e la documentazione delle API (PDF e Markdown) |
| `mongodb/` | struttura delle collection, dati di esempio e script di reset |
| `screenshots/` | immagini dell'applicazione funzionante |
| `video/` | registrazione dimostrativa |
| `branding/` | logo, palette e asset grafici |

## Requisiti

* Flutter (canale stable) con supporto web e Google Chrome
* n8n (in locale, porta 5678)
* MongoDB in locale (porta 27017) e, facoltativo, MongoDB Compass

## Avvio

### 1. MongoDB

1. Avviare MongoDB.
2. Creare il database `fidelity_db` e importare in Compass i file della cartella `mongodb/` nelle collection `users`, `clients`, `purchases_movements`, `rewards_catalog` (*Add Data → Import JSON*). In alternativa usare lo script indicato in `mongodb/`.

### 2. n8n

1. Avviare n8n e aprire `http://localhost:5678`.
2. **Workflows → Import from file**: importare i 6 file JSON della cartella `n8n/`.
3. In un nodo MongoDB selezionare (o creare) la credenziale: connessione `mongodb://localhost:27017`, database `fidelity_db` (se n8n è in Docker usare `host.docker.internal` al posto di `localhost`). Scegliere la stessa credenziale in tutti i nodi MongoDB dei workflow.
4. **Pubblicare** ogni workflow: gli URL devono essere del tipo `http://localhost:5678/webhook/...`.
5. Per Flutter Web, in ogni nodo *Webhook* deve essere presente l'opzione *Allowed Origins (CORS)* con valore `*` (già impostata nei JSON esportati).

| Workflow | Endpoint | Ruoli |
|---|---|---|
| 01 Login e verifica permessi | `/webhook/login` | tutti |
| 02 Ricerca cliente | `/webhook/ricerca-cliente` | tutti |
| 03 Registra acquisto | `/webhook/registra-acquisto` | tutti |
| 04 Storico movimenti e annullamento | `/webhook/movimenti` | storico: tutti; annullamento: Amministratore |
| 05 Catalogo premi e riscatto | `/webhook/premi` | Amministratore |
| 06 Dashboard | `/webhook/dashboard` | Responsabile, Amministratore |

### 3. Flutter

```
cd flutter
flutter pub get
flutter run -d chrome
```

L'indirizzo base di n8n si trova in `lib/services/api_service.dart` (per impostazione `http://localhost:5678/webhook`).

## Utenti di test

| Ruolo | Username | Password | Funzioni |
|---|---|---|---|
| Operatore | `operatore` | `operatore123` | Cassa, Storico |
| Responsabile | `responsabile` | `responsabile123` | Cassa, Storico, Dashboard |
| Amministratore | `admin` | `admin123` | Cassa, Storico (con annullamento), Catalogo Premi, Dashboard |

## Dati di esempio

| Codice tessera | Cliente | Punti iniziali |
|---|---|---|
| FC-0001 | Luca Ferrari | 120 |
| FC-0002 | Giulia Romano | 85 |
| FC-0003 | Marco Esposito | 850 |
| FC-0004 | Sara Conti | 40 |
| FC-0005 | Andrea Marini | 0 |

Catalogo premi: Buono da 5 € (100 punti), Tazza (250), Buono da 20 € (500), Zaino (800); il Cappellino (90) non è disponibile.

## Come provarlo (percorso rapido)

1. Accedere come `operatore`: in **Cassa** cercare `FC-0001` e registrare un acquisto di 25 € → il saldo sale di 25 punti.
2. Aprire **Storico**: il nuovo acquisto compare in cima; provare i filtri per tipo e data. L'Operatore non vede il pulsante *Annulla*.
3. Uscire e accedere come `admin`: in **Storico** annullare l'acquisto appena creato → i punti vengono stornati.
4. In **Catalogo Premi** cercare `FC-0003` e riscattare un premio → il saldo scende del costo del premio.
5. Aprire **Dashboard** (anche come `responsabile`): gli indicatori e i grafici riflettono le operazioni fatte.

## Documentazione

* `n8n/Documentazione_API_Fidelity_Card.pdf`: descrizione di ogni workflow nodo per nodo, struttura dei dati e test Postman con le risposte attese.
* `n8n/README_n8n.md`: istruzioni brevi per importare e provare i workflow.
* `branding/PALETTE_E_LOGO.md`: logo e palette colori.

## Identità grafica

Nome **PuntoFedele**; colore principale `#0F766E` (verde acqua), accento `#F59E0B` (ambra). Logo e palette sono nell'app (`flutter/assets/branding/`) e, separatamente, in `branding/`.

## Limiti noti (semplificazioni didattiche)

Le password sono salvate in chiaro e il ruolo è inviato dal client; in produzione si userebbero password con hash e un token (per esempio JWT) verificato da ogni API.
