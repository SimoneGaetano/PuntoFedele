// ============================================================================
// Script di inizializzazione MongoDB — Fidelity Card (IFTS PW2)
// Fase 1: creazione collection `users` con i 3 ruoli di sistema
// Ogni utente ha: username, password (in chiaro a scopo didattico), ruolo
// ============================================================================

db = db.getSiblingDB("fidelity_db");

// --- 1. Crea la collection users con validatore sul campo 'ruolo' ---
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "password", "ruolo"],
      properties: {
        username: { bsonType: "string", description: "nome utente univoco" },
        password: { bsonType: "string", description: "password (in chiaro a scopo didattico)" },
        ruolo: {
          bsonType: "string",
          enum: ["Operatore", "Responsabile", "Amministratore"],
          description: "ruolo assegnato all'utente"
        },
        nome: { bsonType: "string" },
        cognome: { bsonType: "string" },
        attivo: { bsonType: "bool" }
      }
    }
  }
});

// --- 2. Indice univoco su username ---
db.users.createIndex({ username: 1 }, { unique: true });

// --- 3. Inserimento dei 3 ruoli base ---
db.users.insertMany([
  {
    username: "operatore",
    password: "operatore123",
    ruolo: "Operatore",
    nome: "Mario",
    cognome: "Rossi",
    attivo: true
  },
  {
    username: "responsabile",
    password: "responsabile123",
    ruolo: "Responsabile",
    nome: "Laura",
    cognome: "Bianchi",
    attivo: true
  },
  {
    username: "admin",
    password: "admin123",
    ruolo: "Amministratore",
    nome: "Giuseppe",
    cognome: "Verdi",
    attivo: true
  }
]);

print("Collection 'users' creata e popolata con 3 utenti.");
printjson(db.users.find().toArray());

// ============================================================================
// Fase 1: creazione collection `clients` con dati di prova e saldo punti iniziale
// ============================================================================

// --- 1. Crea la collection clients con validatore ---
db.createCollection("clients", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["nome", "cognome", "email", "saldo_punti"],
      properties: {
        nome: { bsonType: "string" },
        cognome: { bsonType: "string" },
        email: { bsonType: "string" },
        telefono: { bsonType: "string" },
        saldo_punti: { bsonType: "int", description: "saldo punti fedeltà (1€ = 1 pt)" },
        data_registrazione: { bsonType: "date" },
        attivo: { bsonType: "bool" }
      }
    }
  }
});

// --- 2. Indice univoco su email ---
db.clients.createIndex({ email: 1 }, { unique: true });

// --- 3. Inserimento clienti di prova ---
db.clients.insertMany([
  {
    nome: "Luca",
    cognome: "Ferrari",
    email: "luca.ferrari@email.it",
    telefono: "+39 333 1234567",
    saldo_punti: 120,
    data_registrazione: new Date("2025-01-15"),
    attivo: true
  },
  {
    nome: "Giulia",
    cognome: "Romano",
    email: "giulia.romano@email.it",
    telefono: "+39 333 2345678",
    saldo_punti: 85,
    data_registrazione: new Date("2025-02-20"),
    attivo: true
  },
  {
    nome: "Marco",
    cognome: "Esposito",
    email: "marco.esposito@email.it",
    telefono: "+39 333 3456789",
    saldo_punti: 250,
    data_registrazione: new Date("2024-11-10"),
    attivo: true
  },
  {
    nome: "Sara",
    cognome: "Conti",
    email: "sara.conti@email.it",
    telefono: "+39 333 4567890",
    saldo_punti: 40,
    data_registrazione: new Date("2026-03-05"),
    attivo: true
  },
  {
    nome: "Andrea",
    cognome: "Marini",
    email: "andrea.marini@email.it",
    telefono: "+39 333 5678901",
    saldo_punti: 0,
    data_registrazione: new Date("2026-04-12"),
    attivo: true
  }
]);

print("Collection 'clients' creata e popolata con 5 clienti.");
printjson(db.clients.find({}, { _id: 0 }).toArray());

// ============================================================================
// Fase 1: creazione collection `purchases_movements` per lo storico operazioni
// ============================================================================

// --- 0. Drop se già esistente (riversabilità) ---
db.purchases_movements.drop();

// --- 1. Crea la collection purchases_movements con validatore ---
db.createCollection("purchases_movements", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["cliente_id", "tipo", "importo_euro", "punti", "data", "operatore"],
      properties: {
        cliente_id: { bsonType: "objectId", description: "riferimento al cliente" },
        tipo: {
          bsonType: "string",
          enum: ["acquisto", "annullamento", "riscatto"],
          description: "tipo di movimento"
        },
        importo_euro: { bsonType: "number", description: "importo in euro della transazione" },
        punti: { bsonType: "number", description: "punti accumulati (+) o sottratti (-)" },
        data: { bsonType: "date" },
        operatore: { bsonType: "string", description: "username dell'operatore" },
        note: { bsonType: "string" }
      }
    }
  }
});

// --- 2. Indice su cliente_id ---
db.purchases_movements.createIndex({ cliente_id: 1 });

// --- 3. Inserimento movimenti di prova ---
var luca = ObjectId("6ae60ea195d55fb2808de666");
var marco = ObjectId("6ae60ea195d55fb2808de668");
var sara = ObjectId("6ae60ea195d55fb2808de669");

db.purchases_movements.insertMany([
  {
    cliente_id: luca,
    tipo: "acquisto",
    importo_euro: 50.00,
    punti: 50,
    data: new Date("2026-05-10T10:30:00Z"),
    operatore: "operatore",
    note: "Acquisto prodotti alimentari"
  },
  {
    cliente_id: marco,
    tipo: "acquisto",
    importo_euro: 100.00,
    punti: 100,
    data: new Date("2026-05-12T14:15:00Z"),
    operatore: "operatore",
    note: "Acquisto elettronica"
  },
  {
    cliente_id: sara,
    tipo: "acquisto",
    importo_euro: 20.00,
    punti: 20,
    data: new Date("2026-05-15T09:00:00Z"),
    operatore: "operatore",
    note: "Acquisto abbigliamento"
  },
  {
    cliente_id: luca,
    tipo: "annullamento",
    importo_euro: 50.00,
    punti: -50,
    data: new Date("2026-05-11T11:00:00Z"),
    operatore: "admin",
    note: "Storno acquisto errato"
  }
]);

print("Collection 'purchases_movements' creata e popolata con 4 movimenti.");
printjson(db.purchases_movements.find().toArray());

// ============================================================================
// Fase 1: creazione collection `rewards_catalog` con i premi
// ============================================================================

// --- 0. Drop se già esistente (riversabilità) ---
db.rewards_catalog.drop();

// --- 1. Crea la collection rewards_catalog con validatore ---
db.createCollection("rewards_catalog", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["nome", "descrizione", "costo_punti", "disponibile"],
      properties: {
        nome: { bsonType: "string" },
        descrizione: { bsonType: "string" },
        costo_punti: { bsonType: "number", description: "costo in punti fedeltà" },
        disponibile: { bsonType: "bool" },
        data_inserimento: { bsonType: "date" }
      }
    }
  }
});

// --- 2. Indice su costo_punti ---
db.rewards_catalog.createIndex({ costo_punti: 1 });

// --- 3. Inserimento premi di prova ---
db.rewards_catalog.insertMany([
  {
    nome: "Buono 5€",
    descrizione: "Buono sconto da 5 euro spendibile in negozio",
    costo_punti: 50,
    disponibile: true,
    data_inserimento: new Date("2026-01-01")
  },
  {
    nome: "Buono 10€",
    descrizione: "Buono sconto da 10 euro spendibile in negozio",
    costo_punti: 100,
    disponibile: true,
    data_inserimento: new Date("2026-01-01")
  },
  {
    nome: "Tazza",
    descrizione: "Tazza brandizzata dell'azienda",
    costo_punti: 75,
    disponibile: true,
    data_inserimento: new Date("2026-01-01")
  },
  {
    nome: "Shopper",
    descrizione: "Borsa shopper in cotone con logo",
    costo_punti: 60,
    disponibile: true,
    data_inserimento: new Date("2026-01-01")
  },
  {
    nome: "Cappellino",
    descrizione: "Cappellino con visiera brandizzato",
    costo_punti: 90,
    disponibile: false,
    data_inserimento: new Date("2026-01-01")
  }
]);

print("Collection 'rewards_catalog' creata e popolata con 5 premi.");
printjson(db.rewards_catalog.find().toArray());