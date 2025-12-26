import db from '../config/database';
import { Record, QueryParams, QueryResult } from '../types';

export class RecordModel {
  static insert(record: Record): number {
    const stmt = db.prepare(`
      INSERT INTO records (
        record_number, datacenter_name, idc_requirement_number, yes_ticket_number,
        user_unit, cable_type, operator, circuit_number, contact_person,
        start_port, hop1, hop2, hop3, hop4, hop5, end_port, user_cabinet,
        label_complete, cable_standard, remark
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const result = stmt.run(
      record.record_number,
      record.datacenter_name,
      record.idc_requirement_number || null,
      record.yes_ticket_number || null,
      record.user_unit || null,
      record.cable_type || null,
      record.operator || null,
      record.circuit_number || null,
      record.contact_person || null,
      record.start_port || null,
      record.hop1 || null,
      record.hop2 || null,
      record.hop3 || null,
      record.hop4 || null,
      record.hop5 || null,
      record.end_port || null,
      record.user_cabinet || null,
      record.label_complete || 0,
      record.cable_standard || 0,
      record.remark || null
    );

    return result.lastInsertRowid as number;
  }

  static batchInsert(records: Record[]): number[] {
    const insertedIds: number[] = [];
    const insertMany = db.transaction((records: Record[]) => {
      for (const record of records) {
        insertedIds.push(this.insert(record));
      }
    });
    insertMany(records);
    return insertedIds;
  }

  static findAll(params: QueryParams): QueryResult {
    const {
      datacenter_name,
      record_number,
      circuit_number,
      start_port,
      end_port,
      user_cabinet,
      operator,
      cable_type,
      idc_requirement_number,
      yes_ticket_number,
      start_date,
      end_date,
      sort_field = 'created_at',
      sort_order = 'desc',
      page = 1,
      page_size = 20
    } = params;

    const conditions: string[] = [];
    const values: any[] = [];

    if (datacenter_name) {
      conditions.push('datacenter_name = ?');
      values.push(datacenter_name);
    }
    if (record_number) {
      conditions.push('record_number LIKE ?');
      values.push(`%${record_number}%`);
    }
    if (circuit_number) {
      conditions.push('circuit_number LIKE ?');
      values.push(`%${circuit_number}%`);
    }
    if (start_port) {
      conditions.push('start_port LIKE ?');
      values.push(`%${start_port}%`);
    }
    if (end_port) {
      conditions.push('end_port LIKE ?');
      values.push(`%${end_port}%`);
    }
    if (user_cabinet) {
      conditions.push('user_cabinet LIKE ?');
      values.push(`%${user_cabinet}%`);
    }
    if (operator) {
      conditions.push('operator = ?');
      values.push(operator);
    }
    if (cable_type) {
      conditions.push('cable_type = ?');
      values.push(cable_type);
    }
    if (idc_requirement_number) {
      conditions.push('idc_requirement_number LIKE ?');
      values.push(`%${idc_requirement_number}%`);
    }
    if (yes_ticket_number) {
      conditions.push('yes_ticket_number LIKE ?');
      values.push(`%${yes_ticket_number}%`);
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

    const countStmt = db.prepare(`SELECT COUNT(*) as total FROM records ${whereClause}`);
    const countResult = countStmt.get(...values) as { total: number };
    const total = countResult.total;

    const validSortFields = [
      'id', 'record_number', 'datacenter_name', 'idc_requirement_number',
      'yes_ticket_number', 'user_unit', 'cable_type', 'operator',
      'circuit_number', 'start_port', 'end_port', 'user_cabinet',
      'created_at', 'updated_at'
    ];

    const safeSortField = validSortFields.includes(sort_field) ? sort_field : 'created_at';
    const safeSortOrder = sort_order.toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    const offset = (page - 1) * page_size;
    const dataStmt = db.prepare(`
      SELECT * FROM records ${whereClause}
      ORDER BY ${safeSortField} ${safeSortOrder}
      LIMIT ? OFFSET ?
    `);
    const data = dataStmt.all(...values, page_size, offset) as Record[];

    return {
      data,
      total,
      page,
      page_size
    };
  }

  static findById(id: number): Record | undefined {
    const stmt = db.prepare('SELECT * FROM records WHERE id = ?');
    return stmt.get(id) as Record | undefined;
  }

  static update(id: number, data: Partial<Record>): boolean {
    const updates: string[] = [];
    const values: any[] = [];

    const allowedFields = [
      'record_number', 'datacenter_name', 'idc_requirement_number', 'yes_ticket_number',
      'user_unit', 'cable_type', 'operator', 'circuit_number', 'contact_person',
      'start_port', 'hop1', 'hop2', 'hop3', 'hop4', 'hop5', 'end_port',
      'user_cabinet', 'label_complete', 'cable_standard', 'remark'
    ];

    for (const field of allowedFields) {
      if (field in data) {
        updates.push(`${field} = ?`);
        values.push(data[field as keyof Record]);
      }
    }

    if (updates.length === 0) {
      return false;
    }

    updates.push('updated_at = CURRENT_TIMESTAMP');
    values.push(id);

    const stmt = db.prepare(`
      UPDATE records
      SET ${updates.join(', ')}
      WHERE id = ?
    `);

    const result = stmt.run(...values);
    return result.changes > 0;
  }

  static delete(id: number): boolean {
    const stmt = db.prepare('DELETE FROM records WHERE id = ?');
    const result = stmt.run(id);
    return result.changes > 0;
  }

  static batchDelete(ids: number[]): number {
    if (ids.length === 0) {
      return 0;
    }

    const placeholders = ids.map(() => '?').join(',');
    const stmt = db.prepare(`DELETE FROM records WHERE id IN (${placeholders})`);
    const result = stmt.run(...ids);
    return result.changes;
  }

  static getDatacenters(): string[] {
    const stmt = db.prepare('SELECT DISTINCT datacenter_name FROM records ORDER BY datacenter_name');
    const rows = stmt.all() as { datacenter_name: string }[];
    return rows.map(row => row.datacenter_name);
  }

  static getOperators(): string[] {
    const stmt = db.prepare('SELECT DISTINCT operator FROM records WHERE operator IS NOT NULL ORDER BY operator');
    const rows = stmt.all() as { operator: string }[];
    return rows.map(row => row.operator);
  }

  static getCableTypes(): string[] {
    const stmt = db.prepare('SELECT DISTINCT cable_type FROM records WHERE cable_type IS NOT NULL ORDER BY cable_type');
    const rows = stmt.all() as { cable_type: string }[];
    return rows.map(row => row.cable_type);
  }

  static deleteAll(): number {
    const stmt = db.prepare('DELETE FROM records');
    const result = stmt.run();
    return result.changes;
  }
}
