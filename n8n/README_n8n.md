# Workflow n8n – PuntoFedele (Fidelity Card)

Questa cartella contiene i 6 workflow n8n che fanno da backend all'app Flutter Web.
Architettura: **Flutter Web → API n8n → MongoDB** (Flutter non accede mai direttamente a MongoDB).

Descrizione completa di ogni nodo e dei test: vedi `Documentazione_API_Fidelity_Card.pdf`.

## File

| File | Endpoint (`POST`) | Chi può usarla |
|------|-------------------|----------------|
| `01_Login_Verifica_Permessi.json` | `/webhook/login` | tutti |
| `02_Ricerca_Cliente.json` | `/webhook/ricerca-cliente` | utenti autenticati |
| `03_Registra_Acquisto.json` | `/webhook/registra-acquisto` | utenti autenticati |
| `04_Storico_Movimenti_e_Annullamento.json` | `/webhook/movimenti` | storico: tutti; annullamento: Amministratore |
| `05_Catalogo_Premi_e_Riscatto.json` | `/webhook/premi` | Amministratore |
| `06_Dashboard.json` | `/webhook/dashboard` | Responsabile e Amministratore |

## Come importarli

1. In n8n: **Workflows → Import from file** e scegliere un file `.json` (da ripetere per tutti e 6).
2. Aprire un nodo MongoDB e, nel campo *Credential*, selezionare (o creare) la credenziale MongoDB:
   * connessione: *Connection String* `mongodb://localhost:27017`
   * database: `fidelity_db`
   (se n8n gira in Docker, al posto di `localhost` usare `host.docker.internal`).
   Una credenziale selezionata in un nodo va poi scelta anche negli altri nodi MongoDB del workflow.
3. Per l'uso da Flutter Web: in ogni nodo **Webhook**, *Options → Add option → Allowed Origins (CORS)* → `*`.
4. **Pubblicare** ogni workflow (così l'URL è `/webhook/...` e non `/webhook-test/...`).

## Identificare il cliente

Le API 02, 03 e 05 cercano il cliente per **`codice_cliente`** (codice tessera, es. `FC-0001`) oppure per **`email`**.
Se nel body ci sono entrambi vale il codice; il codice è ripulito dagli spazi e portato in maiuscolo (`fc-0001` = `FC-0001`).
Le risposte contengono `cliente.codice_cliente`. L'API 04 (storico) usa invece `cliente_id`, che si ricava da `cliente.id` della risposta del 02.

## Prerequisiti su MongoDB

Database `fidelity_db` con le collection `users`, `clients` (ogni cliente con il campo `codice_cliente`), `purchases_movements` (con la *s*) e `rewards_catalog`.
Dati di prova e struttura: cartella `/mongodb`.

## Come provarli

Con Postman o simili: `POST http://localhost:5678/webhook/<path>`, body *raw JSON*.
Esempi:

```json
// POST /webhook/login
{ "username": "admin", "password": "admin123" }
// risposta: { "success": true, "ruolo": "Amministratore", "nome": "Giuseppe", "cognome": "Verdi", "messaggio": "Login effettuato" }

// POST /webhook/ricerca-cliente
{ "codice_cliente": "FC-0001" }

// POST /webhook/registra-acquisto
{ "codice_cliente": "FC-0001", "importo_euro": 10, "operatore": "operatore" }
```

Utenti di prova: `operatore` / `operatore123`, `responsabile` / `responsabile123`, `admin` / `admin123`.
I body di tutti i test e le risposte attese sono nella documentazione.

## Note

* Le password sono in chiaro su MongoDB e il ruolo viene inviato dal client: semplificazioni didattiche ammesse dal progetto.
* Le funzioni riservate (annullamento, premi, dashboard) sono protette anche dalle API, non solo dall'interfaccia.
