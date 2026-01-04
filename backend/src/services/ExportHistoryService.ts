import db from '../config/database';
import { Request } from 'express';

export interface ExportHistory {
  id?: number;
  user_id?: string;
  export_type: string;
  export_format: string;
  record_count: number;
  file_name: string;
  created_at?: string;
}

export class ExportHistoryService {
  static async create(params: {
    user_id?: string;
    export_type: string;
    export_format: string;
    record_count: number;
    file_name: string;
    req?: Request;
  }): Promise<number> {
    const { user_id, export_type, export_format, record_count, file_name, req } = params;

    const userId = user_id || req?.headers['x-user-id'] as string || 'anonymous';

    const stmt = db.prepare(`
      INSERT INTO export_history (user_id, export_type, export_format, record_count, file_name)
      VALUES (?, ?, ?, ?, ?)
    `);

    const result = stmt.run(
      userId,
      export_type,
      export_format,
      record_count,
      file_name
    );
    return result.lastInsertRowid as number;
  }

  static async query(params: {
    user_id?: string;
    export_type?: string;
    export_format?: string;
    start_date?: string;
    end_date?: string;
    page?: number;
    page_size?: number;
  }): Promise<{ data: ExportHistory[]; total: number }> {
    const {
      user_id,
      export_type,
      export_format,
      start_date,
      end_date,
      page = 1,
      page_size = 20
    } = params;

    const conditions: string[] = [];
    const values: any[] = [];

    if (user_id) {
      conditions.push('user_id = ?');
      values.push(user_id);
    }

    if (export_type) {
      conditions.push('export_type = ?');
      values.push(export_type);
    }

    if (export_format) {
      conditions.push('export_format = ?');
      values.push(export_format);
    }

    if (start_date) {
      conditions.push('created_at >= ?');
      values.push(start_date);
    }

    if (end_date) {
      conditions.push('created_at <= ?');
      values.push(end_date);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countStmt = db.prepare(`SELECT COUNT(*) as total FROM export_history ${whereClause}`);
    const countResult = countStmt.get(...values) as { total: number };
    const total = countResult.total;

    const offset = (page - 1) * page_size;
    const dataStmt = db.prepare(`
      SELECT * FROM export_history
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `);

    const data = dataStmt.all(...values, page_size, offset) as ExportHistory[];

    return { data, total };
  }

  static async deleteOldHistory(daysToKeep: number = 30): Promise<number> {
    const stmt = db.prepare(`
      DELETE FROM export_history
      WHERE created_at < datetime('now', '-' || ? || ' days')
    `);

    const result = stmt.run(daysToKeep);
    return result.changes;
  }

  static async getStatistics(params: {
    start_date?: string;
    end_date?: string;
  }): Promise<{
    total_exports: number;
    exports_by_type: Record<string, number>;
    exports_by_format: Record<string, number>;
    total_records_exported: number;
  }> {
    const { start_date, end_date } = params;

    const conditions: string[] = [];
    const values: any[] = [];

    if (start_date) {
      conditions.push('created_at >= ?');
      values.push(start_date);
    }

    if (end_date) {
      conditions.push('created_at <= ?');
      values.push(end_date);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const totalStmt = db.prepare(`SELECT COUNT(*) as total FROM export_history ${whereClause}`);
    const totalResult = totalStmt.get(...values) as { total: number };

    const typeStmt = db.prepare(`
      SELECT export_type, COUNT(*) as count
      FROM export_history
      ${whereClause}
      GROUP BY export_type
    `);
    const typeResult = typeStmt.all(...values) as Array<{ export_type: string; count: number }>;
    const exportsByType: Record<string, number> = {};
    typeResult.forEach(row => {
      exportsByType[row.export_type] = row.count;
    });

    const formatStmt = db.prepare(`
      SELECT export_format, COUNT(*) as count
      FROM export_history
      ${whereClause}
      GROUP BY export_format
    `);
    const formatResult = formatStmt.all(...values) as Array<{ export_format: string; count: number }>;
    const exportsByFormat: Record<string, number> = {};
    formatResult.forEach(row => {
      exportsByFormat[row.export_format] = row.count;
    });

    const recordsStmt = db.prepare(`
      SELECT SUM(record_count) as total
      FROM export_history
      ${whereClause}
    `);
    const recordsResult = recordsStmt.get(...values) as { total: number | null };

    return {
      total_exports: totalResult.total,
      exports_by_type: exportsByType,
      exports_by_format: exportsByFormat,
      total_records_exported: recordsResult.total || 0
    };
  }
}
