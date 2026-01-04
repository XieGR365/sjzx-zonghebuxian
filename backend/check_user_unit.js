const Database = require('better-sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, 'data/wiring.db');
const db = new Database(dbPath);

const records = db.prepare('SELECT id, record_number, user_unit FROM records WHERE user_unit IS NOT NULL LIMIT 10').all();
console.log('数据库中的 user_unit 数据:');
console.log(JSON.stringify(records, null, 2));

db.close();
