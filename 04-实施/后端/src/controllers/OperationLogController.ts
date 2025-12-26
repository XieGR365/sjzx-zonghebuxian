import { Request, Response } from 'express';
import { OperationLogService } from '../services/OperationLogService';

export class OperationLogController {
  static async query(req: Request, res: Response): Promise<void> {
    try {
      const params = {
        user_id: req.query.user_id as string,
        operation_type: req.query.operation_type as string,
        start_date: req.query.start_date as string,
        end_date: req.query.end_date as string,
        status: req.query.status as string,
        page: parseInt(req.query.page as string) || 1,
        page_size: parseInt(req.query.page_size as string) || 20
      };

      const result = await OperationLogService.query(params);

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      console.error('Query operation logs error:', error);
      res.status(500).json({
        success: false,
        message: '查询操作日志失败',
        errorType: 'QUERY_LOGS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async getStatistics(req: Request, res: Response): Promise<void> {
    try {
      const params = {
        start_date: req.query.start_date as string,
        end_date: req.query.end_date as string
      };

      const statistics = await OperationLogService.getStatistics(params);

      res.json({
        success: true,
        data: statistics
      });
    } catch (error) {
      console.error('Get operation log statistics error:', error);
      res.status(500).json({
        success: false,
        message: '获取操作日志统计失败',
        errorType: 'LOG_STATISTICS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async export(req: Request, res: Response): Promise<void> {
    try {
      const params = {
        user_id: req.query.user_id as string,
        operation_type: req.query.operation_type as string,
        start_date: req.query.start_date as string,
        end_date: req.query.end_date as string,
        status: req.query.status as string
      };

      const logs = await OperationLogService.export(params);

      res.json({
        success: true,
        data: logs
      });
    } catch (error) {
      console.error('Export operation logs error:', error);
      res.status(500).json({
        success: false,
        message: '导出操作日志失败',
        errorType: 'EXPORT_LOGS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async deleteOldLogs(req: Request, res: Response): Promise<void> {
    try {
      const daysToKeep = parseInt(req.query.days_to_keep as string) || 90;

      const deletedCount = await OperationLogService.deleteOldLogs(daysToKeep);

      res.json({
        success: true,
        message: `成功删除 ${deletedCount} 条旧日志`,
        data: {
          deletedCount
        }
      });
    } catch (error) {
      console.error('Delete old logs error:', error);
      res.status(500).json({
        success: false,
        message: '删除旧日志失败',
        errorType: 'DELETE_LOGS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }
}
