// PuntoFedele - CREAZIONE DA ZERO del database fidelity_db
//
// ATTENZIONE: svuota le 4 collection (users, clients, purchases_movements, rewards_catalog)
// e le riempie con i dati di partenza. Usare su un database nuovo o per ripartire da zero.
// Per riportare solo i dati di prova allo stato iniziale senza toccare il resto: reset_dati.js.
//
// Uso: in Compass aprire il pannello >_MONGOSH, incollare TUTTO il blocco e premere Invio.

(function () {
  const d = db.getSiblingDB("fidelity_db");

  ["users", "clients", "purchases_movements", "rewards_catalog"].forEach(c => d[c].deleteMany({}));

  // --- users (password in chiaro: semplificazione didattica) ---
  d.users.insertMany([
    { username: "operatore",    password: "operatore123",    ruolo: "Operatore",      nome: "Mario",    cognome: "Rossi",  attivo: true },
    { username: "responsabile", password: "responsabile123", ruolo: "Responsabile",   nome: "Laura",    cognome: "Bianchi", attivo: true },
    { username: "admin",        password: "admin123",        ruolo: "Amministratore", nome: "Giuseppe", cognome: "Verdi",  attivo: true }
  ]);

  // --- clients ---
  d.clients.insertMany([
    { _id: ObjectId("6ae60ea195d55fb2808de666"), codice_cliente: "FC-0001", nome: "Luca",   cognome: "Ferrari",  email: "luca.ferrari@email.it",   telefono: "3331112233", saldo_punti: 120, data_registrazione: ISODate("2026-01-15T00:00:00Z"), attivo: true },
    { _id: ObjectId("6ae60ea195d55fb2808de667"), codice_cliente: "FC-0002", nome: "Giulia", cognome: "Romano",   email: "giulia.romano@email.it",  telefono: "3332223344", saldo_punti: 85,  data_registrazione: ISODate("2026-02-03T00:00:00Z"), attivo: true },
    { _id: ObjectId("6ae60ea195d55fb2808de668"), codice_cliente: "FC-0003", nome: "Marco",  cognome: "Esposito", email: "marco.esposito@email.it", telefono: "3333334455", saldo_punti: 850, data_registrazione: ISODate("2026-02-20T00:00:00Z"), attivo: true },
    { _id: ObjectId("6ae60ea195d55fb2808de669"), codice_cliente: "FC-0004", nome: "Sara",   cognome: "Conti",    email: "sara.conti@email.it",     telefono: "3334445566", saldo_punti: 40,  data_registrazione: ISODate("2026-03-11T00:00:00Z"), attivo: true },
    { _id: ObjectId("6ae60ea195d55fb2808de66a"), codice_cliente: "FC-0005", nome: "Andrea", cognome: "Marini",   email: "andrea.marini@email.it",  telefono: "3335556677", saldo_punti: 0,   data_registrazione: ISODate("2026-04-02T00:00:00Z"), attivo: true }
  ]);

  // --- purchases_movements (cliente_id e' una STRINGA) ---
  d.purchases_movements.insertMany([
    { _id: ObjectId("6ae753591cd6a04d5f8de666"), cliente_id: "6ae60ea195d55fb2808de666", tipo: "acquisto",     importo_euro: 50,  punti: 50,  data: ISODate("2026-05-10T10:30:00Z"), operatore: "operatore", note: "Acquisto prodotti alimentari" },
    { _id: ObjectId("6ae753591cd6a04d5f8de667"), cliente_id: "6ae60ea195d55fb2808de668", tipo: "acquisto",     importo_euro: 100, punti: 100, data: ISODate("2026-05-12T15:00:00Z"), operatore: "operatore", note: "Acquisto elettronica" },
    { _id: ObjectId("6ae753591cd6a04d5f8de668"), cliente_id: "6ae60ea195d55fb2808de669", tipo: "acquisto",     importo_euro: 20,  punti: 20,  data: ISODate("2026-05-15T09:45:00Z"), operatore: "operatore", note: "Acquisto abbigliamento" },
    { _id: ObjectId("6ae753591cd6a04d5f8de669"), cliente_id: "6ae60ea195d55fb2808de666", tipo: "annullamento", importo_euro: 50,  punti: -50, data: ISODate("2026-05-11T11:00:00Z"), operatore: "admin",     note: "Storno acquisto errato", movimento_originale_id: "6ae753591cd6a04d5f8de666" }
  ]);

  // --- rewards_catalog ---
  d.rewards_catalog.insertMany([
    { _id: ObjectId("6ae6124905bba7c7f88de666"), nome: "Buono da 5 €",  descrizione: "Buono sconto da 5 € sulla spesa successiva", costo_punti: 100, disponibile: true,  data_inserimento: ISODate("2026-01-10T00:00:00Z") },
    { _id: ObjectId("6ae6124905bba7c7f88de667"), nome: "Buono da 20 €", descrizione: "Buono sconto da 20 € sulla spesa successiva", costo_punti: 500, disponibile: true,  data_inserimento: ISODate("2026-01-10T00:00:00Z") },
    { _id: ObjectId("6ae6124905bba7c7f88de668"), nome: "Tazza",         descrizione: "Tazza in ceramica con il logo del negozio", costo_punti: 250, disponibile: true,  data_inserimento: ISODate("2026-01-10T00:00:00Z") },
    { _id: ObjectId("6ae6124905bba7c7f88de669"), nome: "Zaino",         descrizione: "Zaino per la città con il logo del negozio", costo_punti: 800, disponibile: true,  data_inserimento: ISODate("2026-01-10T00:00:00Z") },
    { _id: ObjectId("6ae6124905bba7c7f88de66a"), nome: "Cappellino",    descrizione: "Cappellino con il logo del negozio (esaurito)", costo_punti: 90,  disponibile: false, data_inserimento: ISODate("2026-01-10T00:00:00Z") }
  ]);

  // --- indici: evitano duplicati e velocizzano le ricerche delle API ---
  d.users.createIndex({ username: 1 }, { unique: true });
  d.clients.createIndex({ codice_cliente: 1 }, { unique: true });
  d.clients.createIndex({ email: 1 }, { unique: true });
  d.purchases_movements.createIndex({ cliente_id: 1, data: -1 });

  print("Database fidelity_db creato:");
  ["users", "clients", "purchases_movements", "rewards_catalog"].forEach(c =>
    print("  " + c + ": " + d[c].countDocuments() + " documenti"));
})();
