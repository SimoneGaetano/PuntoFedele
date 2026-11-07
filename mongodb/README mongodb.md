# MongoDB – database `fidelity_db`

Struttura delle collection, dati di esempio e script per ricreare o ripristinare il database di PuntoFedele.

## File di questa cartella

| File | A cosa serve |
|---|---|
| `users.json`, `clients.json`, `purchases_movements.json`, `rewards_catalog.json` | dati di esempio esportati da MongoDB Compass (una collection per file) |
| `crea_database.js` | **crea da zero** il database: svuota le 4 collection e inserisce tutti i dati di partenza, con gli indici |
| `reset_dati.js` | **ripristina** i dati di prova dopo i test: cancella i movimenti creati, rimette i saldi dei clienti, la disponibilità dei premi e riattiva gli utenti |

## Come ricreare il database

**Con Compass, da file JSON**

1. Collegarsi a `mongodb://localhost:27017`, creare il database `fidelity_db`.
2. Per ciascuna delle 4 collection: *Create collection* con il nome esatto, poi *Add Data → Import JSON file* e scegliere il file corrispondente.

**Con lo script** (equivalente)

1. In Compass aprire `fidelity_db` e il pannello **>_MONGOSH**.
2. Incollare **tutto** il contenuto di `crea_database.js` e premere Invio. Alla fine stampa il numero di documenti per collection (3, 5, 4, 5).

Attenzione: lo script cancella i dati presenti nelle 4 collection.

## Come riportare i dati allo stato iniziale

Dopo prove e registrazione del video, nel pannello **>_MONGOSH** incollare **tutto** il contenuto di `reset_dati.js`. Va incollato come un blocco unico: incollando più istruzioni separate, mongosh può eseguirne solo alcune. Alla fine stampa la verifica: 4 movimenti, saldi 120 / 85 / 850 / 40 / 0, 4 premi disponibili, 3 utenti attivi.

## Utenti di test

| Username | Password | Ruolo |
|---|---|---|
| `operatore` | `operatore123` | Operatore |
| `responsabile` | `responsabile123` | Responsabile |
| `admin` | `admin123` | Amministratore |

## Struttura delle collection

### `users`

| Campo | Tipo | Note |
|---|---|---|
| `_id` | ObjectId | |
| `username` | string | usato per il login (univoco) |
| `password` | string | in chiaro: semplificazione didattica |
| `ruolo` | string | `Operatore`, `Responsabile`, `Amministratore` |
| `nome`, `cognome` | string | mostrati nel menu dell'app |
| `attivo` | boolean | un utente non attivo non può accedere |

### `clients`

| Campo | Tipo | Note |
|---|---|---|
| `_id` | ObjectId | |
| `codice_cliente` | string | codice tessera, formato `FC-0001` (univoco): chiave di ricerca principale |
| `nome`, `cognome` | string | |
| `email` | string | chiave di ricerca alternativa (univoca) |
| `telefono` | string | |
| `saldo_punti` | number | punti attuali |
| `data_registrazione` | date | |
| `attivo` | boolean | |

### `purchases_movements`

Contiene acquisti, riscatti e annullamenti, distinti dal campo `tipo`.

| Campo | Tipo | Note |
|---|---|---|
| `_id` | ObjectId | |
| `cliente_id` | string | l'`_id` del cliente scritto come **testo** |
| `tipo` | string | `acquisto`, `riscatto`, `annullamento` |
| `importo_euro` | number | importo dell'acquisto (0 per i riscatti) |
| `punti` | number | con segno: positivo se aggiunge punti, negativo se li toglie |
| `data` | date | |
| `operatore` | string | username di chi ha eseguito l'operazione |
| `note` | string | |
| `premio_id` | string | solo nei `riscatto` |
| `movimento_originale_id` | string | solo negli `annullamento`: `_id` del movimento annullato |

| Tipo | `punti` | `importo_euro` |
|---|---|---|
| `acquisto` | + importo (1 € = 1 punto) | + importo |
| `riscatto` | − costo del premio | 0 |
| `annullamento` di un acquisto | − punti dell'acquisto | − importo |
| `annullamento` di un riscatto | + punti del riscatto | 0 |

Un movimento è **annullato** quando esiste un `annullamento` con `movimento_originale_id` uguale al suo `_id`; il movimento originale non viene mai modificato né cancellato.

### `rewards_catalog`

| Campo | Tipo | Note |
|---|---|---|
| `_id` | ObjectId | |
| `nome`, `descrizione` | string | |
| `costo_punti` | number | |
| `disponibile` | boolean | i premi non disponibili non compaiono nel catalogo e non si possono riscattare |
| `data_inserimento` | date | |

## Relazioni

```
clients (_id) ◀── purchases_movements.cliente_id
rewards_catalog (_id) ◀── purchases_movements.premio_id            (solo riscatti)
purchases_movements (_id) ◀── purchases_movements.movimento_originale_id   (solo annullamenti)
```

Le relazioni sono riferimenti scritti come testo: MongoDB non le controlla, le rispettano i workflow n8n.

## Dati di partenza

| Codice | Cliente | Punti | | Premio | Costo | Disponibile |
|---|---|--:|---|---|--:|:-:|
| FC-0001 | Luca Ferrari | 120 | | Buono da 5 € | 100 | sì |
| FC-0002 | Giulia Romano | 85 | | Buono da 20 € | 500 | sì |
| FC-0003 | Marco Esposito | 850 | | Tazza | 250 | sì |
| FC-0004 | Sara Conti | 40 | | Zaino | 800 | sì |
| FC-0005 | Andrea Marini | 0 | | Cappellino | 90 | no |

Movimenti di partenza: 3 acquisti (Luca 50 €, Marco 100 €, Sara 20 €) e 1 annullamento che storna l'acquisto di Luca (quindi quell'acquisto risulta già annullato).

## Query utili (mongosh)

```javascript
db.clients.findOne({ codice_cliente: "FC-0001" })
db.purchases_movements.find({ cliente_id: "6ae60ea195d55fb2808de666" }).sort({ data: -1 })
db.purchases_movements.find({ tipo: "riscatto" })
db.rewards_catalog.find({ disponibile: true }).sort({ costo_punti: 1 })
db.clients.find().sort({ saldo_punti: -1 }).limit(5)
db.purchases_movements.aggregate([{ $group: { _id: "$tipo", totale: { $sum: 1 } } }])
```
