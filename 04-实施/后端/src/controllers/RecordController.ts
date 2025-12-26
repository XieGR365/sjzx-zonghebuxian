import { Request, Response } from 'express';
import { RecordModel } from '../models/RecordModel';
import { ExcelParser } from '../services/ExcelParser';
import { DataExporter } from '../services/DataExporter';
import { StatisticsService } from '../services/StatisticsService';
import { Record, QueryParams } from '../types';

export class RecordController {
  static async upload(req: Request, res: Response): Promise<void> {
    try {
      const file = req.file;
      if (!file) {
        res.status(400).json({ 
          success: false, 
          message: '请上传Excel文件',
          errorType: 'FILE_REQUIRED'
        });
        return;
      }

      // 解析Excel文件
      const { records, errors } = ExcelParser.parse(file.buffer);
      
      // 处理解析错误
      if (errors.length > 0) {
        // 只返回前5个错误，避免响应过大
        const displayErrors = errors.slice(0, 5);
        
        // 检查是否是严重错误（无法解析文件）
        const hasCriticalError = errors.some(error => 
          error.includes('无法读取Excel文件') || 
          error.includes('无法解析工作表数据')
        );
        
        if (hasCriticalError) {
          res.status(400).json({
            success: false,
            message: `Excel文件解析失败: ${displayErrors[0]}`,
            errorType: 'FILE_PARSE_ERROR',
            details: displayErrors
          });
          return;
        } else {
          // 非严重错误（如数据验证错误），仍然尝试导入有效记录
          console.warn('Excel解析警告:', errors);
        }
      }
      
      // 检查是否有有效记录
      if (records.length === 0) {
        res.status(400).json({
          success: false,
          message: '文件中没有有效的记录数据',
          errorType: 'NO_VALID_RECORDS',
          details: errors
        });
        return;
      }

      // 插入记录
      const insertedIds = RecordModel.batchInsert(records);
      
      // 构建响应
      const response: any = {
        success: true,
        message: `成功导入 ${insertedIds.length} 条记录`,
        data: {
          count: insertedIds.length,
          ids: insertedIds
        }
      };
      
      // 如果有警告，添加到响应中
      if (errors.length > 0) {
        response.warnings = {
          count: errors.length,
          messages: errors.slice(0, 10) // 最多返回10个警告
        };
        response.message += `，有 ${errors.length} 条警告信息`;
      }
      
      res.json(response);
    } catch (error) {
      console.error('Upload error:', error);
      
      // 区分不同类型的错误
      let errorMessage = '文件上传失败';
      let errorType = 'UNKNOWN_ERROR';
      
      if (error instanceof Error) {
        if (error.message.includes('只支持Excel文件')) {
          errorMessage = '只支持Excel文件(.xlsx, .xls)';
          errorType = 'INVALID_FILE_TYPE';
        } else if (error.message.includes('File too large')) {
          errorMessage = '文件大小超过限制(最大10MB)';
          errorType = 'FILE_TOO_LARGE';
        } else {
          errorMessage = `服务器处理错误: ${error.message}`;
          errorType = 'SERVER_ERROR';
        }
      }
      
      res.status(500).json({
        success: false,
        message: errorMessage,
        errorType: errorType,
        errorDetails: error instanceof Error ? error.message : undefined
      });
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

      // 验证分页参数
      if (params.page < 1) params.page = 1;
      if (params.page_size < 1 || params.page_size > 100) params.page_size = 20;

      const result = RecordModel.findAll(params);

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      console.error('Query error:', error);
      res.status(500).json({
        success: false,
        message: '查询失败',
        errorType: 'QUERY_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async getDetail(req: Request, res: Response): Promise<void> {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        res.status(400).json({
          success: false,
          message: '无效的ID，ID必须是数字',
          errorType: 'INVALID_ID'
        });
        return;
      }

      const record = RecordModel.findById(id);
      if (!record) {
        res.status(404).json({
          success: false,
          message: `ID为 ${id} 的记录不存在`,
          errorType: 'RECORD_NOT_FOUND'
        });
        return;
      }

      res.json({
        success: true,
        data: record
      });
    } catch (error) {
      console.error('Get detail error:', error);
      res.status(500).json({
        success: false,
        message: '获取详情失败',
        errorType: 'DETAIL_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
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
      res.status(500).json({
        success: false,
        message: '获取机房列表失败',
        errorType: 'DATACENTERS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
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
      res.status(500).json({
        success: false,
        message: '获取筛选选项失败',
        errorType: 'FILTER_OPTIONS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async export(req: Request, res: Response): Promise<void> {
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
        // 导出时不分页，获取所有数据
        page: 1,
        page_size: 10000 // 设置一个足够大的值，确保获取所有数据
      };

      // 获取要导出的数据
      const result = RecordModel.findAll(params);
      const records = result.data;

      // 获取导出格式
      const format = (req.query.format as string) || 'excel';
      
      // 验证格式是否支持
      if (!DataExporter.SUPPORTED_FORMATS.includes(format.toLowerCase())) {
        res.status(400).json({
          success: false,
          message: `不支持的导出格式: ${format}。支持的格式: ${DataExporter.SUPPORTED_FORMATS.join(', ')}`
        });
        return;
      }

      // 导出数据
      const { buffer, mimeType, extension } = DataExporter.export(records, format);

      // 设置响应头
      res.setHeader('Content-Type', mimeType);
      res.setHeader('Content-Disposition', `attachment; filename="综合布线记录_${new Date().toISOString().split('T')[0]}.${extension}"`);
      res.setHeader('Content-Length', buffer.length);

      // 返回导出数据
      res.send(buffer);
    } catch (error) {
      console.error('Export error:', error);
      res.status(500).json({
        success: false,
        message: '数据导出失败',
        errorType: 'EXPORT_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async getStatistics(req: Request, res: Response): Promise<void> {
    try {
      // 获取综合统计数据
      const statistics = StatisticsService.getOverallStatistics();
      
      res.json({
        success: true,
        data: statistics
      });
    } catch (error) {
      console.error('Get statistics error:', error);
      res.status(500).json({
        success: false,
        message: '获取统计数据失败',
        errorType: 'STATISTICS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }

  static async getDatacenterStatistics(req: Request, res: Response): Promise<void> {
    try {
      // 获取按机房的详细统计数据
      const statistics = StatisticsService.getDatacenterStatistics();
      
      res.json({
        success: true,
        data: statistics
      });
    } catch (error) {
      console.error('Get datacenter statistics error:', error);
      res.status(500).json({
        success: false,
        message: '获取机房统计数据失败',
        errorType: 'DATACENTER_STATISTICS_ERROR',
        errorDetails: error instanceof Error ? error.message : undefined
      });
    }
  }
}
