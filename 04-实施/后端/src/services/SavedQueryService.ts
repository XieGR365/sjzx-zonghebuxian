import db from '../config/database';

export interface SavedQuery {
  id?: number;
  user_id?: string;
  query_name: string;
  query_params: string;
  created_at?: string;
  updated_at?: string;
}

export class SavedQueryService {
  static async create(params: {
    user_id?: string;
    query_name: string;
    query_params: Record<string, any>;
  }): Promise<number> {
    const { user_id, query_name, query_params } = params;

    const stmt = db.prepare(`
      INSERT INTO saved_queries (user_id, query_name, query_params)
      VALUES (?, ?, ?)
    `);

    const result = stmt.run(user_id || 'anonymous', query_name, JSON.stringify(query_params));
    return result.lastInsertRowid as number;
  }

  static async query(params: {
    user_id?: string;
    page?: number;
    page_size?: number;
  }): Promise<{ data: SavedQuery[]; total: number }> {
    const { user_id, page = 1, page_size = 20 } = params;

    const conditions: string[] = ['user_id = ?'];
    const values: any[] = [user_id || 'anonymous'];

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    const countStmt = db.prepare(`SELECT COUNT(*) as total FROM saved_queries ${whereClause}`);
    const countResult = countStmt.get(...values) as { total: number };
    const total = countResult.total;

    const offset = (page - 1) * page_size;
    const dataStmt = db.prepare(`
      SELECT * FROM saved_queries
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `);

    const data = dataStmt.all(...values, page_size, offset) as SavedQuery[];

    data.forEach(item => {
      try {
        item.query_params = JSON.parse(item.query_params as any);
      } catch (e) {
        item.query_params = {};
      }
    });

    return { data, total };
  }

  static async getById(id: number, user_id?: string): Promise<SavedQuery | null> {
    const stmt = db.prepare(`
      SELECT * FROM saved_queries
      WHERE id = ? AND user_id = ?
    `);

    const result = stmt.get(id, user_id || 'anonymous') as SavedQuery | undefined;

    if (!result) {
      return null;
    }

    try {
      result.query_params = JSON.parse(result.query_params as any);
    } catch (e) {
      result.query_params = {};
    }

    return result;
  }

  static async update(
    id: number,
    params: {
      user_id?: string;
      query_name?: string;
      query_params?: Record<string, any>;
    }
  ): Promise<boolean> {
    const { user_id, query_name, query_params } = params;
    const updates: string[] = [];
    const values: any[] = [];

    if (query_name) {
      updates.push('query_name = ?');
      values.push(query_name);
    }

    if (query_params) {
      updates.push('query_params = ?');
      values.push(JSON.stringify(query_params));
    }

    updates.push('updated_at = CURRENT_TIMESTAMP');

    values.push(id, user_id || 'anonymous');

    const stmt = db.prepare(`
      UPDATE saved_queries
      SET ${updates.join(', ')}
      WHERE id = ? AND user_id = ?
    `);

    const result = stmt.run(...values);
    return result.changes > 0;
  }

  static async delete(id: number, user_id?: string): Promise<boolean> {
    const stmt = db.prepare(`
      DELETE FROM saved_queries
      WHERE id = ? AND user_id = ?
    `);

    const result = stmt.run(id, user_id || 'anonymous');
    return result.changes > 0;
  }
}
