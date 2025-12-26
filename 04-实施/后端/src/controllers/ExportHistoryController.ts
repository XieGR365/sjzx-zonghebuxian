import { Request, Response } from 'express';
import { ExportHistoryService } from '../services/ExportHistoryService';

export class ExportHistoryController {
  static async query(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.headers['x-user-id'] as string || 'anonymous';
      const params = {
        user_id: userId,
        export_type: req.query.export_type as string,
        export_format: req.query.export_format as string,
        start_date: req.query.start_date as string,
        end_date: req.query.end_date as string,
        page: parseInt(req.query.page as string) || 1,
        page_size: parseInt(req.query.page_size as string) || 20
      };

      const result = await ExportHistoryService.query(params);

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      console.error('Query export history error:', error);
      res.status(500).json({
        success: false,
        message: '查询导出历史失败',
        errorType: 'QUERY_EXPORT_HISTORY_ERROR',
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

      const statistics = await ExportHistoryService.getStatistics(params);

      res.json({
        success: true,
        data: statistics
      });
    } catch (error) {
      console.error('Get export history statistics error:', error);
      res.status(500).json({
        success: false,
        message: '获取导出历史统计失败',
        errorType: 'EXPORT_HISTORY_STATISTICS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async deleteOldHistory(req: Request, res: Response): Promise<void> {
    try {
      const daysToKeep = parseInt(req.query.days_to_keep as string) || 30;

      const deletedCount = await ExportHistoryService.deleteOldHistory(daysToKeep);

      res.json({
        success: true,
        message: `成功删除 ${deletedCount} 条旧导出记录`,
        data: {
          deletedCount
        }
      });
    } catch (error) {
      console.error('Delete old export history error:', error);
      res.status(500).json({
        success: false,
        message: '删除旧导出记录失败',
        errorType: 'DELETE_EXPORT_HISTORY_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }
}
