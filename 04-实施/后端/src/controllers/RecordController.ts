import { Request, Response } from 'express';
import { RecordModel } from '../models/RecordModel';
import { ExcelParser } from '../services/ExcelParser';
import { Record, QueryParams } from '../types';

export class RecordController {
  static async upload(req: Request, res: Response): Promise<void> {
    try {
      const file = req.file;
      if (!file) {
        res.status(400).json({ success: false, message: '请上传文件' });
        return;
      }

      const records = ExcelParser.parse(file.buffer);
      if (records.length === 0) {
        res.status(400).json({ success: false, message: '文件中没有有效的记录数据' });
        return;
      }

      const insertedIds = RecordModel.batchInsert(records);

      res.json({
        success: true,
        message: `成功导入 ${insertedIds.length} 条记录`,
        data: {
          count: insertedIds.length,
          ids: insertedIds
        }
      });
    } catch (error) {
      console.error('Upload error:', error);
      res.status(500).json({ success: false, message: '文件上传失败' });
    }
  }

  static async query(req: Request, res: Response): Promise<void> {
    try {
      const params: QueryParams = {
        datacenter_name: req.query.datacenter_name as string,
        record_number: req.query.record_number as string,
        circuit_number: req.query.circuit_number as string,
        start_port: req.query.start_port as string,
        end_port: req.query.end_port as string,
        user_cabinet: req.query.user_cabinet as string,
        operator: req.query.operator as string,
        cable_type: req.query.cable_type as string,
        idc_requirement_number: req.query.idc_requirement_number as string,
        yes_ticket_number: req.query.yes_ticket_number as string,
        page: parseInt(req.query.page as string) || 1,
        page_size: parseInt(req.query.page_size as string) || 20
      };

      const result = RecordModel.findAll(params);

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      console.error('Query error:', error);
      res.status(500).json({ success: false, message: '查询失败' });
    }
  }

  static async getDetail(req: Request, res: Response): Promise<void> {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        res.status(400).json({ success: false, message: '无效的ID' });
        return;
      }

      const record = RecordModel.findById(id);
      if (!record) {
        res.status(404).json({ success: false, message: '记录不存在' });
        return;
      }

      res.json({
        success: true,
        data: record
      });
    } catch (error) {
      console.error('Get detail error:', error);
      res.status(500).json({ success: false, message: '获取详情失败' });
    }
  }

  static async getDatacenters(req: Request, res: Response): Promise<void> {
    try {
      const datacenters = RecordModel.getDatacenters();
      res.json({
        success: true,
        data: datacenters
      });
    } catch (error) {
      console.error('Get datacenters error:', error);
      res.status(500).json({ success: false, message: '获取机房列表失败' });
    }
  }

  static async getFilterOptions(req: Request, res: Response): Promise<void> {
    try {
      const [datacenters, operators, cableTypes] = await Promise.all([
        RecordModel.getDatacenters(),
        RecordModel.getOperators(),
        RecordModel.getCableTypes()
      ]);

      res.json({
        success: true,
        data: {
          datacenters,
          operators,
          cableTypes
        }
      });
    } catch (error) {
      console.error('Get filter options error:', error);
      res.status(500).json({ success: false, message: '获取筛选选项失败' });
    }
  }

  static async clearAll(req: Request, res: Response): Promise<void> {
    try {
      const count = RecordModel.deleteAll();
      res.json({
        success: true,
        message: `已清空 ${count} 条记录`
      });
    } catch (error) {
      console.error('Clear all error:', error);
      res.status(500).json({ success: false, message: '清空数据失败' });
    }
  }
}
