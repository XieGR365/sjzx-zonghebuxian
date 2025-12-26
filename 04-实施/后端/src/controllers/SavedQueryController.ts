import { Request, Response } from 'express';
import { SavedQueryService } from '../services/SavedQueryService';

export class SavedQueryController {
  static async create(req: Request, res: Response): Promise<void> {
    try {
      const { query_name, query_params } = req.body;

      if (!query_name || !query_params) {
        res.status(400).json({
          success: false,
          message: '缺少必要参数',
          errorType: 'MISSING_PARAMS'
        });
        return;
      }

      const userId = req.headers['x-user-id'] as string || 'anonymous';

      const id = await SavedQueryService.create({
        user_id: userId,
        query_name,
        query_params
      });

      res.json({
        success: true,
        message: '查询条件保存成功',
        data: { id }
      });
    } catch (error) {
      console.error('Create saved query error:', error);
      res.status(500).json({
        success: false,
        message: '保存查询条件失败',
        errorType: 'CREATE_QUERY_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async query(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.headers['x-user-id'] as string || 'anonymous';
      const page = parseInt(req.query.page as string) || 1;
      const page_size = parseInt(req.query.page_size as string) || 20;

      const result = await SavedQueryService.query({
        user_id: userId,
        page,
        page_size
      });

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      console.error('Query saved queries error:', error);
      res.status(500).json({
        success: false,
        message: '查询保存的查询条件失败',
        errorType: 'QUERY_SAVED_QUERIES_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async getById(req: Request, res: Response): Promise<void> {
    try {
      const id = parseInt(req.params.id);
      const userId = req.headers['x-user-id'] as string || 'anonymous';

      const savedQuery = await SavedQueryService.getById(id, userId);

      if (!savedQuery) {
        res.status(404).json({
          success: false,
          message: `ID为 ${id} 的保存查询不存在`,
          errorType: 'SAVED_QUERY_NOT_FOUND'
        });
        return;
      }

      res.json({
        success: true,
        data: savedQuery
      });
    } catch (error) {
      console.error('Get saved query error:', error);
      res.status(500).json({
        success: false,
        message: '获取保存的查询条件失败',
        errorType: 'GET_SAVED_QUERY_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async update(req: Request, res: Response): Promise<void> {
    try {
      const id = parseInt(req.params.id);
      const { query_name, query_params } = req.body;
      const userId = req.headers['x-user-id'] as string || 'anonymous';

      const success = await SavedQueryService.update(id, {
        user_id: userId,
        query_name,
        query_params
      });

      if (!success) {
        res.status(404).json({
          success: false,
          message: `ID为 ${id} 的保存查询不存在`,
          errorType: 'SAVED_QUERY_NOT_FOUND'
        });
        return;
      }

      res.json({
        success: true,
        message: '查询条件更新成功'
      });
    } catch (error) {
      console.error('Update saved query error:', error);
      res.status(500).json({
        success: false,
        message: '更新查询条件失败',
        errorType: 'UPDATE_QUERY_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async delete(req: Request, res: Response): Promise<void> {
    try {
      const id = parseInt(req.params.id);
      const userId = req.headers['x-user-id'] as string || 'anonymous';

      const success = await SavedQueryService.delete(id, userId);

      if (!success) {
        res.status(404).json({
          success: false,
          message: `ID为 ${id} 的保存查询不存在`,
          errorType: 'SAVED_QUERY_NOT_FOUND'
        });
        return;
      }

      res.json({
        success: true,
        message: '查询条件删除成功'
      });
    } catch (error) {
      console.error('Delete saved query error:', error);
      res.status(500).json({
        success: false,
        message: '删除查询条件失败',
        errorType: 'DELETE_QUERY_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }
}
