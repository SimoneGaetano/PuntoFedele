db = db.getSiblingDB("fidelity_db");

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

print("--- Clienti inseriti ---");
printjson(db.clients.find().toArray());