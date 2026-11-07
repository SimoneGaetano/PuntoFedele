db = db.getSiblingDB("fidelity_db");

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

// --- 2. Indice su costo_punti per ordinamento ---
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

print("--- Premi inseriti ---");
printjson(db.rewards_catalog.find().toArray());