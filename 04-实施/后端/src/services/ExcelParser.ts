import * as XLSX from 'xlsx';
import { Record } from '../types';

export class ExcelParser {
  static parse(buffer: Buffer): Record[] {
    const workbook = XLSX.read(buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as any[][];

    if (jsonData.length < 2) {
      return [];
    }

    const headers = jsonData[0].map((h: any) => String(h).trim());
    const records: Record[] = [];

    for (let i = 1; i < jsonData.length; i++) {
      const row = jsonData[i];
      if (!row || row.length === 0) continue;

      const record: Record = {
        record_number: this.getValue(row, headers, '登记表编号') || '',
        datacenter_name: this.getValue(row, headers, '机房名称') || '',
        idc_requirement_number: this.getValue(row, headers, 'IDC需求编号'),
        yes_ticket_number: this.getValue(row, headers, 'YES工单编号'),
        user_unit: this.getValue(row, headers, '用户单位'),
        cable_type: this.getValue(row, headers, '线缆类型'),
        operator: this.getValue(row, headers, '运营商'),
        circuit_number: this.getValue(row, headers, '线路编号'),
        contact_person: this.getValue(row, headers, '报障人/联系方式'),
        start_port: this.getValue(row, headers, '起始端口（A端）'),
        hop1: this.getValue(row, headers, '一跳'),
        hop2: this.getValue(row, headers, '二跳'),
        hop3: this.getValue(row, headers, '三跳'),
        hop4: this.getValue(row, headers, '四跳'),
        hop5: this.getValue(row, headers, '五跳'),
        end_port: this.getValue(row, headers, '目标端口（Z端）'),
        user_cabinet: this.getValue(row, headers, '用户机柜'),
        label_complete: this.parseBoolean(this.getValue(row, headers, '线路标签是否齐全')),
        cable_standard: this.parseBoolean(this.getValue(row, headers, '线路是否规范')),
        remark: this.getValue(row, headers, '备注')
      };

      if (record.record_number && record.datacenter_name) {
        records.push(record);
      }
    }

    return records;
  }

  private static getValue(row: any[], headers: string[], fieldName: string): string | undefined {
    const index = headers.findIndex(h => h.includes(fieldName));
    if (index === -1 || index >= row.length) return undefined;
    const value = row[index];
    return value !== undefined && value !== null ? String(value).trim() : undefined;
  }

  private static parseBoolean(value: string | undefined): number {
    if (!value) return 0;
    const normalized = value.toLowerCase().trim();
    if (normalized === '是' || normalized === 'yes' || normalized === 'true' || normalized === '1') {
      return 1;
    }
    return 0;
  }
}
