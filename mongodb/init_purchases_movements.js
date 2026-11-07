db = db.getSiblingDB("fidelity_db");

// Drop se esiste per ricreare con il validatore aggiornato (stringa invece di ObjectId)
db.purchases_movements.drop();

// Crea la collection con validatore che accetta cliente_id come stringa
db.createCollection("purchases_movements", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["cliente_id", "tipo", "importo_euro", "punti", "data", "operatore"],
      properties: {
        cliente_id: { bsonType: "string" },
        tipo: { bsonType: "string", enum: ["acquisto", "annullamento", "riscatto"] },
        importo_euro: { bsonType: "number" },
        punti: { bsonType: "number" },
        data: { bsonType: "date" },
        operatore: { bsonType: "string" },
        note: { bsonType: "string" }
      }
    }
  }
});

// Indice su cliente_id
db.purchases_movements.createIndex({ cliente_id: 1 });

// ID clienti come stringhe semplici (non ObjectId)
var luca = "6ae60ea195d55fb2808de666";
var marco = "6ae60ea195d55fb2808de668";
var sara = "6ae60ea195d55fb2808de669";

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

print("--- Movimenti inseriti ---");
printjson(db.purchases_movements.find().toArray());