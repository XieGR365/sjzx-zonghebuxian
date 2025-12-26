import db from '../config/database';
import { Request } from 'express';

export interface OperationLog {
  id?: number;
  user_id?: string;
  username?: string;
  operation_type: string;
  operation_content: string;
  operation_details?: string;
  ip_address?: string;
  user_agent?: string;
  status?: string;
  error_message?: string;
  created_at?: string;
}

export class OperationLogService {
  static OPERATION_TYPES = {
    UPLOAD: 'upload',
    QUERY: 'query',
    VIEW_DETAIL: 'view_detail',
    EXPORT: 'export',
    CREATE: 'create',
    UPDATE: 'update',
    DELETE: 'delete',
    BATCH_DELETE: 'batch_delete',
    LOGIN: 'login',
    LOGOUT: 'logout',
    SAVE_QUERY: 'save_query',
    DELETE_QUERY: 'delete_query'
  };

  static async log(params: {
    operation_type: string;
    operation_content: string;
    operation_details?: string;
    req?: Request;
    status?: string;
    error_message?: string;
  }): Promise<number> {
    const {
      operation_type,
      operation_content,
      operation_details,
      req,
      status = 'success',
      error_message
    } = params;

    const userId = req?.headers['x-user-id'] as string || 'anonymous';
    const username = req?.headers['x-username'] as string || 'anonymous';
    const ipAddress = req?.ip || req?.socket.remoteAddress || '';
    const userAgent = req?.headers['user-agent'] || '';

    const stmt = db.prepare(`
      INSERT INTO operation_logs (
        user_id, username, operation_type, operation_content,
        operation_details, ip_address, user_agent, status, error_message
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const result = stmt.run(
      userId,
      username,
      operation_type,
      operation_content,
      operation_details || null,
      ipAddress,
      userAgent,
      status,
      error_message || null
    );

    return result.lastInsertRowid as number;
  }

  static async query(params: {
    user_id?: string;
    operation_type?: string;
    start_date?: string;
    end_date?: string;
    status?: string;
    page?: number;
    page_size?: number;
  }): Promise<{ data: OperationLog[]; total: number }> {
    const {
      user_id,
      operation_type,
      start_date,
      end_date,
      status,
      page = 1,
      page_size = 20
    } = params;

    const conditions: string[] = [];
    const values: any[] = [];

    if (user_id) {
      conditions.push('user_id = ?');
      values.push(user_id);
    }

    if (operation_type) {
      conditions.push('operation_type = ?');
      values.push(operation_type);
    }

    if (start_date) {
      conditions.push('created_at >= ?');
      values.push(start_date);
    }

    if (end_date) {
      conditions.push('created_at <= ?');
      values.push(end_date);
    }

    if (status) {
      conditions.push('status = ?');
      values.push(status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countStmt = db.prepare(`SELECT COUNT(*) as total FROM operation_logs ${whereClause}`);
    const countResult = countStmt.get(...values) as { total: number };
    const total = countResult.total;

    const offset = (page - 1) * page_size;
    const dataStmt = db.prepare(`
      SELECT * FROM operation_logs
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `);

    const data = dataStmt.all(...values, page_size, offset) as OperationLog[];

    return { data, total };
  }

  static async export(params: {
    user_id?: string;
    operation_type?: string;
    start_date?: string;
    end_date?: string;
    status?: string;
  }): Promise<OperationLog[]> {
    const {
      user_id,
      operation_type,
      start_date,
      end_date,
      status
    } = params;

    const conditions: string[] = [];
    const values: any[] = [];

    if (user_id) {
      conditions.push('user_id = ?');
      values.push(user_id);
    }

    if (operation_type) {
      conditions.push('operation_type = ?');
      values.push(operation_type);
    }

    if (start_date) {
      conditions.push('created_at >= ?');
      values.push(start_date);
    }

    if (end_date) {
      conditions.push('created_at <= ?');
      values.push(end_date);
    }

    if (status) {
      conditions.push('status = ?');
      values.push(status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const stmt = db.prepare(`
      SELECT * FROM operation_logs
      ${whereClause}
      ORDER BY created_at DESC
    `);

    return stmt.all(...values) as OperationLog[];
  }

  static async getStatistics(params: {
    start_date?: string;
    end_date?: string;
  }): Promise<{
    total_operations: number;
    operations_by_type: Record<string, number>;
    operations_by_status: Record<string, number>;
    operations_by_user: Record<string, number>;
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

    const totalStmt = db.prepare(`SELECT COUNT(*) as total FROM operation_logs ${whereClause}`);
    const totalResult = totalStmt.get(...values) as { total: number };

    const typeStmt = db.prepare(`
      SELECT operation_type, COUNT(*) as count
      FROM operation_logs
      ${whereClause}
      GROUP BY operation_type
    `);
    const typeResult = typeStmt.all(...values) as Array<{ operation_type: string; count: number }>;
    const operationsByType: Record<string, number> = {};
    typeResult.forEach(row => {
      operationsByType[row.operation_type] = row.count;
    });

    const statusStmt = db.prepare(`
      SELECT status, COUNT(*) as count
      FROM operation_logs
      ${whereClause}
      GROUP BY status
    `);
    const statusResult = statusStmt.all(...values) as Array<{ status: string; count: number }>;
    const operationsByStatus: Record<string, number> = {};
    statusResult.forEach(row => {
      operationsByStatus[row.status] = row.count;
    });

    const userStmt = db.prepare(`
      SELECT username, COUNT(*) as count
      FROM operation_logs
      ${whereClause}
      GROUP BY username
      ORDER BY count DESC
      LIMIT 10
    `);
    const userResult = userStmt.all(...values) as Array<{ username: string; count: number }>;
    const operationsByUser: Record<string, number> = {};
    userResult.forEach(row => {
      operationsByUser[row.username] = row.count;
    });

    return {
      total_operations: totalResult.total,
      operations_by_type: operationsByType,
      operations_by_status: operationsByStatus,
      operations_by_user: operationsByUser
    };
  }

  static async deleteOldLogs(daysToKeep: number = 90): Promise<number> {
    const stmt = db.prepare(`
      DELETE FROM operation_logs
      WHERE created_at < datetime('now', '-' || ? || ' days')
    `);

    const result = stmt.run(daysToKeep);
    return result.changes;
  }
}
