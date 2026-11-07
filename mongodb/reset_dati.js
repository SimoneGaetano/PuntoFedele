// PuntoFedele - RIPRISTINO dei dati di prova (database fidelity_db)
//
// Cosa fa:
//   1. cancella i movimenti creati durante i test (tiene solo i 4 movimenti di partenza);
//   2. ricrea i 4 movimenti di partenza se qualcuno e' stato cancellato (non modifica quelli presenti);
//   3. rimette i saldi punti dei 5 clienti ai valori iniziali;
//   4. rimette la disponibilita' dei premi (il Cappellino non e' disponibile);
//   5. riattiva i 3 utenti di test.
// Non cancella ne' ricrea clienti, premi e utenti: per ripartire da zero usare crea_database.js.
//
// Uso: in Compass aprire il pannello >_MONGOSH, incollare TUTTO il blocco e premere Invio.
// Il blocco e' unico di proposito: incollando piu' istruzioni separate, mongosh puo' eseguirne solo alcune.

(function () {
  const d = db.getSiblingDB("fidelity_db");

  // 1. movimenti di partenza (cliente_id e' una STRINGA: l'_id del cliente scritto come testo)
  const movimentiBase = [
    { _id: ObjectId("6ae753591cd6a04d5f8de666"), cliente_id: "6ae60ea195d55fb2808de666", tipo: "acquisto",
      importo_euro: 50, punti: 50, data: ISODate("2026-05-10T10:30:00Z"), operatore: "operatore",
      note: "Acquisto prodotti alimentari" },
    { _id: ObjectId("6ae753591cd6a04d5f8de667"), cliente_id: "6ae60ea195d55fb2808de668", tipo: "acquisto",
      importo_euro: 100, punti: 100, data: ISODate("2026-05-12T15:00:00Z"), operatore: "operatore",
      note: "Acquisto elettronica" },
    { _id: ObjectId("6ae753591cd6a04d5f8de668"), cliente_id: "6ae60ea195d55fb2808de669", tipo: "acquisto",
      importo_euro: 20, punti: 20, data: ISODate("2026-05-15T09:45:00Z"), operatore: "operatore",
      note: "Acquisto abbigliamento" },
    { _id: ObjectId("6ae753591cd6a04d5f8de669"), cliente_id: "6ae60ea195d55fb2808de666", tipo: "annullamento",
      importo_euro: 50, punti: -50, data: ISODate("2026-05-11T11:00:00Z"), operatore: "admin",
      note: "Storno acquisto errato", movimento_originale_id: "6ae753591cd6a04d5f8de666" }
  ];
  const idBase = movimentiBase.map(m => m._id);

  const cancellati = d.purchases_movements.deleteMany({ _id: { $nin: idBase } }).deletedCount;

  // 2. ricrea solo quelli mancanti ($setOnInsert non tocca i documenti gia' presenti)
  let ricreati = 0;
  movimentiBase.forEach(m => {
    const r = d.purchases_movements.updateOne({ _id: m._id }, { $setOnInsert: m }, { upsert: true });
    if (r.upsertedCount) ricreati++;
  });

  // 3. saldi iniziali
  const saldi = [
    ["6ae60ea195d55fb2808de666", 120],  // FC-0001 Luca Ferrari
    ["6ae60ea195d55fb2808de667", 85],   // FC-0002 Giulia Romano
    ["6ae60ea195d55fb2808de668", 850],  // FC-0003 Marco Esposito
    ["6ae60ea195d55fb2808de669", 40],   // FC-0004 Sara Conti
    ["6ae60ea195d55fb2808de66a", 0]     // FC-0005 Andrea Marini
  ];
  saldi.forEach(([id, saldo]) =>
    d.clients.updateOne({ _id: ObjectId(id) }, { $set: { saldo_punti: saldo } }));

  // 4. disponibilita' dei premi
  d.rewards_catalog.updateMany(
    { _id: { $in: [ObjectId("6ae6124905bba7c7f88de666"), ObjectId("6ae6124905bba7c7f88de667"),
                    ObjectId("6ae6124905bba7c7f88de668"), ObjectId("6ae6124905bba7c7f88de669")] } },
    { $set: { disponibile: true } });
  d.rewards_catalog.updateOne({ _id: ObjectId("6ae6124905bba7c7f88de66a") }, { $set: { disponibile: false } });

  // 5. utenti di test attivi
  d.users.updateMany({ username: { $in: ["operatore", "responsabile", "admin"] } }, { $set: { attivo: true } });

  // verifica
  print("Movimenti di test cancellati: " + cancellati + " | movimenti base ricreati: " + ricreati);
  print("Movimenti totali (atteso 4): " + d.purchases_movements.countDocuments());
  print("Saldi (atteso 120, 85, 850, 40, 0):");
  d.clients.find({}, { _id: 0, codice_cliente: 1, saldo_punti: 1 }).sort({ codice_cliente: 1 })
    .forEach(c => print("  " + c.codice_cliente + " -> " + c.saldo_punti));
  print("Premi disponibili (atteso 4): " + d.rewards_catalog.countDocuments({ disponibile: true }));
  print("Utenti attivi (atteso 3): " + d.users.countDocuments({ attivo: true }));
})();
