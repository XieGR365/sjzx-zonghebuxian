import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';
import dotenv from 'dotenv';

dotenv.config({ path: path.join(__dirname, '../../.env') });

const dbPath = process.env.DB_PATH || path.join(__dirname, '../../data/wiring.db');
const dataDir = path.dirname(dbPath);

if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const db = new Database(dbPath);

db.pragma('journal_mode = WAL');

const initDb = () => {
  const createTableSql = `
    CREATE TABLE IF NOT EXISTS records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      record_number TEXT NOT NULL,
      datacenter_name TEXT NOT NULL,
      idc_requirement_number TEXT,
      yes_ticket_number TEXT,
      user_unit TEXT,
      cable_type TEXT,
      operator TEXT,
      circuit_number TEXT,
      contact_person TEXT,
      start_port TEXT,
      hop1 TEXT,
      hop2 TEXT,
      hop3 TEXT,
      hop4 TEXT,
      hop5 TEXT,
      end_port TEXT,
      user_cabinet TEXT,
      label_complete INTEGER DEFAULT 0,
      cable_standard INTEGER DEFAULT 0,
      remark TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS operation_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      username TEXT,
      operation_type TEXT NOT NULL,
      operation_content TEXT,
      operation_details TEXT,
      ip_address TEXT,
      user_agent TEXT,
      status TEXT DEFAULT 'success',
      error_message TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS saved_queries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      query_name TEXT NOT NULL,
      query_params TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS export_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      export_type TEXT NOT NULL,
      export_format TEXT NOT NULL,
      record_count INTEGER,
      file_name TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `;

  db.exec(createTableSql);

  const indexes = [
    'CREATE INDEX IF NOT EXISTS idx_datacenter_name ON records(datacenter_name)',
    'CREATE INDEX IF NOT EXISTS idx_record_number ON records(record_number)',
    'CREATE INDEX IF NOT EXISTS idx_circuit_number ON records(circuit_number)',
    'CREATE INDEX IF NOT EXISTS idx_start_port ON records(start_port)',
    'CREATE INDEX IF NOT EXISTS idx_end_port ON records(end_port)',
    'CREATE INDEX IF NOT EXISTS idx_user_cabinet ON records(user_cabinet)',
    'CREATE INDEX IF NOT EXISTS idx_operator ON records(operator)',
    'CREATE INDEX IF NOT EXISTS idx_cable_type ON records(cable_type)',
    'CREATE INDEX IF NOT EXISTS idx_idc_requirement_number ON records(idc_requirement_number)',
    'CREATE INDEX IF NOT EXISTS idx_yes_ticket_number ON records(yes_ticket_number)',
    'CREATE INDEX IF NOT EXISTS idx_operation_logs_user_id ON operation_logs(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_operation_logs_operation_type ON operation_logs(operation_type)',
    'CREATE INDEX IF NOT EXISTS idx_operation_logs_created_at ON operation_logs(created_at)',
    'CREATE INDEX IF NOT EXISTS idx_saved_queries_user_id ON saved_queries(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_export_history_user_id ON export_history(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_export_history_created_at ON export_history(created_at)'
  ];

  indexes.forEach(indexSql => db.exec(indexSql));
};

initDb();

export default db;
