const Database = require('better-sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, 'data/wiring.db');
const db = new Database(dbPath);

const records = db.prepare('SELECT id, record_number, contact_person FROM records LIMIT 10').all();
console.log(JSON.stringify(records, null, 2));

db.close();
