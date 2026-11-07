db = db.getSiblingDB("fidelity_db");

db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "password", "ruolo"],
      properties: {
        username: { bsonType: "string" },
        password: { bsonType: "string" },
        ruolo: { bsonType: "string", enum: ["Operatore", "Responsabile", "Amministratore"] },
        nome: { bsonType: "string" },
        cognome: { bsonType: "string" },
        attivo: { bsonType: "bool" }
      }
    }
  }
});

db.users.createIndex({ username: 1 }, { unique: true });

db.users.insertMany([
  { username: "operatore", password: "operatore123", ruolo: "Operatore", nome: "Mario", cognome: "Rossi", attivo: true },
  { username: "responsabile", password: "responsabile123", ruolo: "Responsabile", nome: "Laura", cognome: "Bianchi", attivo: true },
  { username: "admin", password: "admin123", ruolo: "Amministratore", nome: "Giuseppe", cognome: "Verdi", attivo: true }
]);

print("--- Utenti inseriti ---");
printjson(db.users.find().toArray());