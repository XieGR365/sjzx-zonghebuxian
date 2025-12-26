import * as XLSX from 'xlsx';
import { Record } from '../types';

export class DataExporter {
  // 支持的导出格式
  static readonly SUPPORTED_FORMATS = ['excel', 'csv', 'json'];

  // 字段映射：数据库字段 -> 中文列名
  static readonly FIELD_MAPPING: Record<string, string> = {
    record_number: '登记表编号',
    datacenter_name: '机房名称',
    idc_requirement_number: 'IDC需求编号',
    yes_ticket_number: 'YES工单编号',
    user_unit: '用户单位',
    cable_type: '线缆类型',
    operator: '运营商',
    circuit_number: '线路编号',
    contact_person: '报障人/联系方式',
    start_port: '起始端口（A端）',
    hop1: '一跳',
    hop2: '二跳',
    hop3: '三跳',
    hop4: '四跳',
    hop5: '五跳',
    end_port: '目标端口（Z端）',
    user_cabinet: '用户机柜',
    label_complete: '线路标签是否齐全',
    cable_standard: '线路是否规范',
    remark: '备注',
    created_at: '创建时间',
    updated_at: '更新时间'
  };

  // 准备导出数据，支持自定义字段
  private static prepareExportData(records: Record[], fields?: string[]): any[] {
    const exportFields = fields || Object.keys(this.FIELD_MAPPING);

    return records.map(record => {
      const exportRecord: any = {};

      exportFields.forEach(field => {
        if (field in record) {
          const value = record[field as keyof Record];
          
          if (field === 'label_complete' || field === 'cable_standard') {
            exportRecord[this.FIELD_MAPPING[field]] = value === 1 ? '是' : '否';
          } else {
            exportRecord[this.FIELD_MAPPING[field]] = value;
          }
        }
      });

      return exportRecord;
    });
  }

  // 导出为Excel格式
  static exportToExcel(records: Record[], fields?: string[]): Buffer {
    const exportData = this.prepareExportData(records, fields);

    const worksheet = XLSX.utils.json_to_sheet(exportData);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, '布线记录');
    
    return Buffer.from(XLSX.write(workbook, { bookType: 'xlsx', type: 'buffer' }));
  }

  // 导出为CSV格式
  static exportToCSV(records: Record[], fields?: string[]): Buffer {
    const exportData = this.prepareExportData(records, fields);

    const worksheet = XLSX.utils.json_to_sheet(exportData);
    return Buffer.from(XLSX.utils.sheet_to_csv(worksheet));
  }

  // 导出为JSON格式
  static exportToJSON(records: Record[], fields?: string[]): Buffer {
    const exportFields = fields || Object.keys(this.FIELD_MAPPING);

    const exportData = records.map(record => {
      const exportRecord: any = {};

      exportFields.forEach(field => {
        if (field in record) {
          exportRecord[field] = record[field as keyof Record];
        }
      });

      return exportRecord;
    });

    return Buffer.from(JSON.stringify(exportData, null, 2), 'utf-8');
  }

  // 根据格式导出数据
  static export(records: Record[], format: string, fields?: string[]): { buffer: Buffer; mimeType: string; extension: string } {
    let buffer: Buffer;
    let mimeType: string;
    let extension: string;

    switch (format.toLowerCase()) {
      case 'excel':
        buffer = this.exportToExcel(records, fields);
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        extension = 'xlsx';
        break;
      
      case 'csv':
        buffer = this.exportToCSV(records, fields);
        mimeType = 'text/csv';
        extension = 'csv';
        break;
      
      case 'json':
        buffer = this.exportToJSON(records, fields);
        mimeType = 'application/json';
        extension = 'json';
        break;
      
      default:
        throw new Error(`不支持的导出格式: ${format}。支持的格式: ${this.SUPPORTED_FORMATS.join(', ')}`);
    }

    return { buffer, mimeType, extension };
  }
}