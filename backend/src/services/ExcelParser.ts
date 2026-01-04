import * as XLSX from 'xlsx';
import { Record as RecordType } from '../types';

export class ExcelParser {
  private static readonly HEADER_MAPPINGS: { [key: string]: string[] } = {
    record_number: ['登记表编号', '记录编号', '编号', '序号', '记录号', 'ID', 'id', 'No', 'NO'],
    datacenter_name: ['机房名称', '机房', '数据中心', '中心名称', '机房地点', '站点名称'],
    idc_requirement_number: ['IDC需求编号', 'IDC编号', '需求编号', 'IDC需求', '需求ID'],
    yes_ticket_number: ['YES工单编号', '工单编号', 'YES编号', '工单ID', '工单号'],
    execution_date: ['执行时间', '实施时间', '完成时间', '开通时间', '部署时间', '时间'],
    user_unit: ['用户单位', '单位', '客户单位', '使用单位', '客户名称', '用户', '用户名称'],
    purpose: ['用途', '使用用途', '业务用途', '线路用途', '用途说明'],
    cable_type: ['线缆类型', '线缆', '类型', '线类型', '线种', '线缆种类'],
    operator: ['运营商', '运行商', '营运商', '电信运营商', '服务提供商'],
    circuit_number: ['线路编号', '线路', '电路编号', '电路', '电路号', '线路ID', '运营商编号'],
    contact_person: ['报障人/联系方式', '联系人', '联系电话', '联系方式', '联系人电话', '联系信息', '报障人'],
    start_port: ['起始端口（A端）', '起始端口', 'A端端口', '起点', '起始点', 'A端', '运营商端口'],
    hop1: ['一跳', '中间节点1', '节点1', '跳接1', '转接1'],
    hop2: ['二跳', '中间节点2', '节点2', '跳接2', '转接2'],
    hop3: ['三跳', '中间节点3', '节点3', '跳接3', '转接3'],
    hop4: ['四跳', '中间节点4', '节点4', '跳接4', '转接4'],
    hop5: ['五跳', '中间节点5', '节点5', '跳接5', '转接5'],
    end_port: ['目标端口（Z端）', '目标端口', 'Z端端口', '终点', '终止点', 'Z端'],
    user_cabinet: ['用户机柜', '机柜', '用户架', '机架', '机柜编号', '机架编号'],
    label_complete: ['线路标签是否齐全', '标签是否齐全', '标签齐全', '标签完整', '标签状态'],
    cable_standard: ['线路是否规范', '是否规范', '规范', '线路规范', '规范状态'],
    remark: ['备注', '说明', '备注信息', '备注栏', '说明信息']
  };

  static parse(buffer: Buffer): { records: RecordType[]; errors: string[] } {
    const errors: string[] = [];
    let workbook;

    try {
      // 尝试读取Excel文件
      workbook = XLSX.read(buffer, { 
        type: 'buffer',
        cellDates: false,
        raw: false,
        dateNF: 'yyyy/mm/dd'
      });
    } catch (error) {
      errors.push(`无法读取Excel文件: ${error instanceof Error ? error.message : '未知错误'}`);
      return { records: [], errors };
    }

    if (!workbook.SheetNames || workbook.SheetNames.length === 0) {
      errors.push('Excel文件中没有工作表');
      return { records: [], errors };
    }

    const allRecords: RecordType[] = [];

    for (const sheetName of workbook.SheetNames) {
      const worksheet = workbook.Sheets[sheetName];
      let jsonData;

      try {
        jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1, blankrows: false }) as any[][];
      } catch (error) {
        errors.push(`无法解析工作表"${sheetName}"数据: ${error instanceof Error ? error.message : '未知错误'}`);
        continue;
      }

      if (jsonData.length < 2) {
        errors.push(`工作表"${sheetName}"中数据行数不足`);
        continue;
      }

      const records = this.parseSheet(jsonData, sheetName);
      allRecords.push(...records);
    }

    return { records: allRecords, errors };
  }

  private static parseSheet(jsonData: any[][], sheetName: string): RecordType[] {
    const records: RecordType[] = [];

    // 识别表头行
    const headerRowIndex = this.findHeaderRow(jsonData);
    let headers = jsonData[headerRowIndex].map((h: any) => String(h || '').trim());

    // 检查是否是多行表头结构，如果是则合并表头
    if (headerRowIndex + 1 < jsonData.length) {
      const nextRow = jsonData[headerRowIndex + 1];
      if (nextRow) {
        const nextRowHeaders = nextRow.map((h: any) => String(h || '').trim());
        const hasSubHeaders = nextRowHeaders.some(h => 
          h && (h.includes('跳') || h.includes('节点') || h.includes('端口'))
        );

        // 如果下一行包含子表头，则合并表头
        if (hasSubHeaders) {
          const mergedHeaders: string[] = [];
          for (let i = 0; i < Math.max(headers.length, nextRowHeaders.length); i++) {
            const header1 = headers[i] || '';
            const header2 = nextRowHeaders[i] || '';
            
            // 如果第二行有内容，优先使用第二行的内容
            if (header2 && header2.trim() !== '') {
              mergedHeaders.push(header2);
            } else {
              mergedHeaders.push(header1);
            }
          }
          headers = mergedHeaders;
        }
      }
    }

    // 确定数据行的起始位置
    let dataStartRow = headerRowIndex + 1;
    
    // 检查是否是多行表头结构
    if (headerRowIndex + 1 < jsonData.length) {
      const nextRow = jsonData[headerRowIndex + 1];
      if (nextRow) {
        const nextRowHeaders = nextRow.map((h: any) => String(h || '').trim());
        const hasSubHeaders = nextRowHeaders.some(h => 
          h && (h.includes('跳') || h.includes('节点') || h.includes('端口'))
        );

        // 如果下一行包含子表头，数据行从headerRowIndex + 2开始
        if (hasSubHeaders) {
          dataStartRow = headerRowIndex + 2;
        }
      }
    }

    // 从数据行开始解析数据
    for (let i = dataStartRow; i < jsonData.length; i++) {
      const row = jsonData[i];
      if (!row || row.length === 0) continue;

      const record: RecordType = {
        record_number: this.getValue(row, headers, this.HEADER_MAPPINGS.record_number) || '',
        datacenter_name: this.getValue(row, headers, this.HEADER_MAPPINGS.datacenter_name) || '',
        idc_requirement_number: this.getValue(row, headers, this.HEADER_MAPPINGS.idc_requirement_number),
        yes_ticket_number: this.getValue(row, headers, this.HEADER_MAPPINGS.yes_ticket_number),
        execution_date: this.getValue(row, headers, this.HEADER_MAPPINGS.execution_date),
        user_unit: this.getValue(row, headers, this.HEADER_MAPPINGS.user_unit),
        purpose: this.getValue(row, headers, this.HEADER_MAPPINGS.purpose),
        cable_type: this.getValue(row, headers, this.HEADER_MAPPINGS.cable_type),
        operator: this.getValue(row, headers, this.HEADER_MAPPINGS.operator),
        circuit_number: this.getValue(row, headers, this.HEADER_MAPPINGS.circuit_number),
        contact_person: this.getValue(row, headers, this.HEADER_MAPPINGS.contact_person),
        start_port: this.getValue(row, headers, this.HEADER_MAPPINGS.start_port),
        hop1: this.getValue(row, headers, this.HEADER_MAPPINGS.hop1),
        hop2: this.getValue(row, headers, this.HEADER_MAPPINGS.hop2),
        hop3: this.getValue(row, headers, this.HEADER_MAPPINGS.hop3),
        hop4: this.getValue(row, headers, this.HEADER_MAPPINGS.hop4),
        hop5: this.getValue(row, headers, this.HEADER_MAPPINGS.hop5),
        end_port: this.getValue(row, headers, this.HEADER_MAPPINGS.end_port),
        user_cabinet: this.getValue(row, headers, this.HEADER_MAPPINGS.user_cabinet),
        label_complete: this.parseBoolean(this.getValue(row, headers, this.HEADER_MAPPINGS.label_complete)),
        cable_standard: this.parseBoolean(this.getValue(row, headers, this.HEADER_MAPPINGS.cable_standard)),
        remark: this.getValue(row, headers, this.HEADER_MAPPINGS.remark)
      };

      // 数据验证
      const validationErrors = this.validateRecord(record, i + 1);
      if (validationErrors.length > 0) {
        continue;
      }

      // 数据清洗
      this.cleanRecord(record);

      // 只要有基本信息就添加记录
      if (record.record_number || record.datacenter_name || record.circuit_number) {
        records.push(record);
      }
    }

    return records;
  }

  // 查找表头行，支持多种表头识别策略
  private static findHeaderRow(data: any[][]): number {
    // 策略1: 寻找包含最多预期表头的行
    let maxMatchCount = 0;
    let headerRowIndex = 0;

    for (let i = 0; i < Math.min(5, data.length); i++) {
      const row = data[i];
      if (!row) continue;

      const rowHeaders = row.map((h: any) => String(h || '').trim());
      let matchCount = 0;

      // 检查当前行包含多少预期表头
      Object.values(this.HEADER_MAPPINGS).forEach(expectedHeaders => {
        for (const expectedHeader of expectedHeaders) {
          if (rowHeaders.some(header => 
            header && (header === expectedHeader || 
             header.includes(expectedHeader) || 
             expectedHeader.includes(header) ||
             header.replace(/[^\w]/g, '') === expectedHeader.replace(/[^\w]/g, '') ||
             header.toLowerCase() === expectedHeader.toLowerCase())
          )) {
            matchCount++;
            break;
          }
        }
      });

      if (matchCount > maxMatchCount) {
        maxMatchCount = matchCount;
        headerRowIndex = i;
      }
    }

    // 检查是否是多行表头结构（如第1行有基础表头，第2行有子表头）
    if (headerRowIndex + 1 < data.length) {
      const nextRow = data[headerRowIndex + 1];
      if (nextRow) {
        const nextRowHeaders = nextRow.map((h: any) => String(h || '').trim());
        const hasSubHeaders = nextRowHeaders.some(h => 
          h && (h.includes('跳') || h.includes('节点') || h.includes('端口'))
        );
        
        // 如果下一行包含子表头（如一跳、二跳等），则使用多行表头
        if (hasSubHeaders) {
          return headerRowIndex;
        }
      }
    }

    return headerRowIndex;
  }

  // 增强的getValue方法，支持更灵活的匹配
  private static getValue(row: any[], headers: string[], fieldNames: string[]): string | undefined {
    // 策略1: 精确匹配（最高优先级）
    for (const fieldName of fieldNames) {
      const index = headers.findIndex(h => h === fieldName);
      if (index !== -1 && index < row.length) {
        const value = row[index];
        return this.cleanValue(value);
      }
    }

    // 策略2: 表头包含字段名（中等优先级）
    for (const fieldName of fieldNames) {
      const index = headers.findIndex(h => 
        h && h.includes(fieldName) && h.length > fieldName.length
      );
      if (index !== -1 && index < row.length) {
        const value = row[index];
        return this.cleanValue(value);
      }
    }

    // 策略3: 字段名包含表头（较低优先级）
    for (const fieldName of fieldNames) {
      const index = headers.findIndex(h => 
        h && fieldName.includes(h) && fieldName.length > h.length
      );
      if (index !== -1 && index < row.length) {
        const value = row[index];
        return this.cleanValue(value);
      }
    }

    // 策略4: 移除空格和特殊字符后的匹配（最低优先级）
    const cleanedHeaders = headers.map(h => h && h.replace(/[^\w]/g, '').toLowerCase());
    for (const fieldName of fieldNames) {
      const cleanedFieldName = fieldName.replace(/[^\w]/g, '').toLowerCase();
      const index = cleanedHeaders.findIndex(h => h === cleanedFieldName);
      if (index !== -1 && index < row.length) {
        const value = row[index];
        return this.cleanValue(value);
      }
    }

    return undefined;
  }

  // 清洗单个值
  private static cleanValue(value: any): string | undefined {
    if (value === undefined || value === null) {
      return undefined;
    }

    // 检查是否是Excel日期序列号
    if (typeof value === 'number' && value > 20000 && value < 60000) {
      const date = new Date((value - 25569) * 86400 * 1000);
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return `${year}/${month}/${day}`;
    }

    let cleaned = String(value).trim();
    
    // 移除多余的空格和特殊字符
    cleaned = cleaned.replace(/\s+/g, ' ');
    cleaned = cleaned.replace(/[\r\n\t]/g, '');
    
    // 如果是空字符串，返回undefined
    if (cleaned === '' || cleaned === 'null' || cleaned === 'undefined') {
      return undefined;
    }

    return cleaned;
  }

  // 数据验证
  private static validateRecord(record: RecordType, rowNumber: number): string[] {
    const errors: string[] = [];

    // 基本验证：至少需要一个标识符（放宽条件，允许更多字段作为标识符）
    if (!record.record_number && 
        !record.circuit_number && 
        !record.datacenter_name &&
        !record.idc_requirement_number &&
        !record.yes_ticket_number) {
      errors.push('缺少基本标识符信息');
    }

    // 线缆类型验证（放宽验证，只做标准化，不拒绝）
    if (record.cable_type) {
      // 只记录警告，不拒绝导入
      const validCableTypes = ['光纤', '网线', '铜缆', '光缆', '双绞线', '同轴电缆'];
      const lowerCableType = record.cable_type.toLowerCase();
      const isValid = validCableTypes.some(type => 
        type.toLowerCase() === lowerCableType || 
        lowerCableType.includes(type.toLowerCase())
      );
      if (!isValid) {
        // 不添加到错误列表，只在清洗时处理
        // errors.push(`未知的线缆类型: ${record.cable_type}`);
      }
    }

    // 联系方式格式验证（放宽验证，允许各种格式）
    if (record.contact_person) {
      // 移除严格的格式验证，只做基本清洗
      // const hasContactInfo = /(\d{11}|@)/.test(record.contact_person);
      // if (!hasContactInfo) {
      //   errors.push(`联系方式格式可能不正确: ${record.contact_person}`);
      // }
    }

    return errors;
  }

  // 数据清洗
  private static cleanRecord(record: RecordType): void {
    // 标准化线缆类型（增强处理，支持数字类型和更多格式）
    if (record.cable_type) {
      const cableTypeMap: Record<string, string> = {
        '光纤线': '光纤',
        '光缆': '光纤',
        '网线': '网线',
        '铜缆': '网线',
        '双绞线': '网线',
        '五类线': '网线',
        '六类线': '网线',
        '同轴电缆': '同轴电缆',
        '同轴': '同轴电缆',
        '电力电缆': '电力电缆',
        '通讯电缆': '通讯电缆',
        // 支持数字类型的线缆类型
        '1': '光纤',
        '2': '网线',
        '3': '铜缆',
        '4': '同轴电缆',
        '5': '电力电缆',
        '6': '通讯电缆'
      };
      
      const lowerType = record.cable_type.toLowerCase();
      
      if (/^\d+$/.test(record.cable_type)) {
        const cableTypeMap: { [key: string]: string } = {
          '1': '光纤',
          '2': '网线',
          '3': '同轴电缆',
          '4': '电话线',
          '5': '其他'
        };
        record.cable_type = cableTypeMap[record.cable_type] || record.cable_type;
      } else {
        const cableTypeMap: { [key: string]: string } = {
          '光纤': '光纤',
          '网线': '网线',
          '同轴电缆': '同轴电缆',
          '电话线': '电话线',
          '光缆': '光纤',
          '双绞线': '网线',
          'cat5': '网线',
          'cat6': '网线',
          'cat7': '网线',
          '五类线': '网线',
          '六类线': '网线',
          '超五类': '网线',
          '超六类': '网线'
        };
        
        for (const [key, value] of Object.entries(cableTypeMap)) {
          if (lowerType.includes(key) || lowerType === key) {
            record.cable_type = value;
            break;
          }
        }
      }
    }

    if (record.operator) {
      const operatorMap: { [key: string]: string } = {
        '电信': '中国电信',
        '移动': '中国移动',
        '联通': '中国联通',
        '铁通': '中国移动',
        '网通': '中国联通',
        '中国电信': '中国电信',
        '中国移动': '中国移动',
        '中国联通': '中国联通',
        '中国铁通': '中国移动',
        '中国网通': '中国联通',
        '广电': '中国广电',
        '中国广电': '中国广电',
        '有线': '中国广电',
        '长城宽带': '长城宽带',
        '鹏博士': '鹏博士'
      };
      
      const lowerOperator = record.operator.toLowerCase();
      for (const [key, value] of Object.entries(operatorMap)) {
        if (lowerOperator.includes(key) || lowerOperator === key) {
          record.operator = value as string;
          break;
        }
      }
    }

    if (record.datacenter_name) {
      // 移除冗余信息，提取核心机房名称
      let cleanedName = record.datacenter_name.trim();
      
      // 移除常见前缀和后缀
      const prefixes = ['机房', '数据中心', '中心', '站点', 'IDC', 'idc'];
      const suffixes = ['机房', '数据中心', '中心', '站点', 'IDC', 'idc'];
      
      // 移除前缀
      for (const prefix of prefixes) {
        if (cleanedName.startsWith(prefix)) {
          cleanedName = cleanedName.slice(prefix.length).trim();
          break;
        }
      }
      
      // 移除后缀
      for (const suffix of suffixes) {
        if (cleanedName.endsWith(suffix)) {
          cleanedName = cleanedName.slice(0, -suffix.length).trim();
          break;
        }
      }
      
      // 移除ODF架编号等特殊格式信息
      cleanedName = cleanedName.replace(/ODF架编号：|odf架编号：|\([^)]*\)/g, '').trim();
      
      const datacenterMap: { [key: string]: string } = {
        '临港二期': '临港二期',
        '唐镇': '唐镇',
        '国定': '国定',
        '深圳云引擎': '深圳云引擎',
        '美盛': '美盛',
        '通联': '通联',
        '金桥7号楼': '金桥7号楼',
        '金桥': '金桥',
        '上海': '上海',
        '北京': '北京',
        '广州': '广州',
        '深圳': '深圳'
      };
      
      for (const [key, value] of Object.entries(datacenterMap)) {
        if (cleanedName.includes(key) || cleanedName === key) {
          cleanedName = value;
          break;
        }
      }
      
      record.datacenter_name = cleanedName;
    }

    // 标准化端口格式
    const standardizePort = (port: string | undefined): string | undefined => {
      if (!port) return undefined;
      
      let cleanedPort = port.trim();
      
      // 移除空格和特殊字符
      cleanedPort = cleanedPort.replace(/\s+/g, '');
      
      // 标准化常见端口格式
      cleanedPort = cleanedPort.replace(/端口|Port|port/g, '');
      
      // 确保ODF格式统一
      cleanedPort = cleanedPort.replace(/odf|ODF/g, 'ODF');
      
      return cleanedPort;
    };
    
    // 应用端口标准化
    record.start_port = standardizePort(record.start_port);
    record.hop1 = standardizePort(record.hop1);
    record.hop2 = standardizePort(record.hop2);
    record.hop3 = standardizePort(record.hop3);
    record.hop4 = standardizePort(record.hop4);
    record.hop5 = standardizePort(record.hop5);
    record.end_port = standardizePort(record.end_port);

    // 标准化机柜格式
    if (record.user_cabinet) {
      let cleanedCabinet = record.user_cabinet.trim();
      
      // 移除机柜前缀
      cleanedCabinet = cleanedCabinet.replace(/机柜|机柜编号|架|机架/g, '').trim();
      
      // 标准化格式
      if (!cleanedCabinet.startsWith('机柜')) {
        cleanedCabinet = `机柜-${cleanedCabinet}`;
      }
      
      record.user_cabinet = cleanedCabinet;
    }

    // 移除备注中的多余信息
    if (record.remark && record.remark.length > 200) {
      record.remark = record.remark.substring(0, 200) + '...';
    }
  }

  // 增强的布尔值解析
  private static parseBoolean(value: string | undefined): number {
    if (!value) return 0;
    
    const normalized = value.toLowerCase().trim();
    const trueValues = ['是', 'yes', 'true', '1', '√', '正确', '完整', '齐全', '规范'];
    
    return trueValues.includes(normalized) ? 1 : 0;
  }
}
