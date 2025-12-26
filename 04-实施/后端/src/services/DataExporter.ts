import * as XLSX from 'xlsx';
import { Record } from '../types';

export class DataExporter {
  // 支持的导出格式
  static readonly SUPPORTED_FORMATS = ['excel', 'csv', 'json'];

  // 导出为Excel格式
  static exportToExcel(records: Record[]): Buffer {
    // 准备导出数据，添加友好的列名
    const exportData = records.map(record => ({
      '登记表编号': record.record_number,
      '机房名称': record.datacenter_name,
      'IDC需求编号': record.idc_requirement_number,
      'YES工单编号': record.yes_ticket_number,
      '用户单位': record.user_unit,
      '线缆类型': record.cable_type,
      '运营商': record.operator,
      '线路编号': record.circuit_number,
      '报障人/联系方式': record.contact_person,
      '起始端口（A端）': record.start_port,
      '一跳': record.hop1,
      '二跳': record.hop2,
      '三跳': record.hop3,
      '四跳': record.hop4,
      '五跳': record.hop5,
      '目标端口（Z端）': record.end_port,
      '用户机柜': record.user_cabinet,
      '线路标签是否齐全': record.label_complete === 1 ? '是' : '否',
      '线路是否规范': record.cable_standard === 1 ? '是' : '否',
      '备注': record.remark,
      '创建时间': record.created_at,
      '更新时间': record.updated_at
    }));

    // 创建工作表
    const worksheet = XLSX.utils.json_to_sheet(exportData);
    
    // 创建工作簿
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, '布线记录');
    
    // 转换为Buffer
    return Buffer.from(XLSX.write(workbook, { bookType: 'xlsx', type: 'buffer' }));
  }

  // 导出为CSV格式
  static exportToCSV(records: Record[]): Buffer {
    // 准备导出数据，添加友好的列名
    const exportData = records.map(record => ({
      '登记表编号': record.record_number,
      '机房名称': record.datacenter_name,
      'IDC需求编号': record.idc_requirement_number,
      'YES工单编号': record.yes_ticket_number,
      '用户单位': record.user_unit,
      '线缆类型': record.cable_type,
      '运营商': record.operator,
      '线路编号': record.circuit_number,
      '报障人/联系方式': record.contact_person,
      '起始端口（A端）': record.start_port,
      '一跳': record.hop1,
      '二跳': record.hop2,
      '三跳': record.hop3,
      '四跳': record.hop4,
      '五跳': record.hop5,
      '目标端口（Z端）': record.end_port,
      '用户机柜': record.user_cabinet,
      '线路标签是否齐全': record.label_complete === 1 ? '是' : '否',
      '线路是否规范': record.cable_standard === 1 ? '是' : '否',
      '备注': record.remark,
      '创建时间': record.created_at,
      '更新时间': record.updated_at
    }));

    // 创建工作表
    const worksheet = XLSX.utils.json_to_sheet(exportData);
    
    // 转换为CSV
    return Buffer.from(XLSX.utils.sheet_to_csv(worksheet));
  }

  // 导出为JSON格式
  static exportToJSON(records: Record[]): Buffer {
    // 准备导出数据，保持原始字段名
    const exportData = records.map(record => ({
      record_number: record.record_number,
      datacenter_name: record.datacenter_name,
      idc_requirement_number: record.idc_requirement_number,
      yes_ticket_number: record.yes_ticket_number,
      user_unit: record.user_unit,
      cable_type: record.cable_type,
      operator: record.operator,
      circuit_number: record.circuit_number,
      contact_person: record.contact_person,
      start_port: record.start_port,
      hop1: record.hop1,
      hop2: record.hop2,
      hop3: record.hop3,
      hop4: record.hop4,
      hop5: record.hop5,
      end_port: record.end_port,
      user_cabinet: record.user_cabinet,
      label_complete: record.label_complete,
      cable_standard: record.cable_standard,
      remark: record.remark,
      created_at: record.created_at,
      updated_at: record.updated_at
    }));

    // 转换为JSON字符串并返回Buffer
    return Buffer.from(JSON.stringify(exportData, null, 2), 'utf-8');
  }

  // 根据格式导出数据
  static export(records: Record[], format: string): { buffer: Buffer; mimeType: string; extension: string } {
    let buffer: Buffer;
    let mimeType: string;
    let extension: string;

    switch (format.toLowerCase()) {
      case 'excel':
        buffer = this.exportToExcel(records);
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        extension = 'xlsx';
        break;
      
      case 'csv':
        buffer = this.exportToCSV(records);
        mimeType = 'text/csv';
        extension = 'csv';
        break;
      
      case 'json':
        buffer = this.exportToJSON(records);
        mimeType = 'application/json';
        extension = 'json';
        break;
      
      default:
        throw new Error(`不支持的导出格式: ${format}。支持的格式: ${this.SUPPORTED_FORMATS.join(', ')}`);
    }

    return { buffer, mimeType, extension };
  }
}