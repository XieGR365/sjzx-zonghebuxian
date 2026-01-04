const XLSX = require('xlsx');
const fs = require('fs');

const filePath = 'd:\\TREA\\sjzx-zonghebuxian\\01-原始素材\\参考资料\\_EXCEL\\金桥7号楼机房综合布线信息统计表20251219最新版.xlsx';

try {
  const buffer = fs.readFileSync(filePath);
  const workbook = XLSX.read(buffer, { 
    type: 'buffer',
    cellDates: true,
    raw: false
  });

  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1, blankrows: false });
  
  console.log('=== Excel文件结构分析 ===\n');
  
  // 显示前3行的详细结构
  for (let i = 0; i < Math.min(3, jsonData.length); i++) {
    console.log(`第${i + 1}行 (${jsonData[i].length}列):`);
    jsonData[i].forEach((col, idx) => {
      console.log(`  [${idx}] ${col}`);
    });
    console.log('');
  }
  
  // 模拟ExcelParser的表头合并逻辑
  const headerRowIndex = 0;
  let headers = jsonData[headerRowIndex].map(h => String(h || '').trim());
  
  console.log('=== 原始表头（第1行）===');
  headers.forEach((h, idx) => console.log(`  [${idx}] ${h}`));
  
  // 检查是否是多行表头结构
  if (headerRowIndex + 1 < jsonData.length) {
    const nextRow = jsonData[headerRowIndex + 1];
    if (nextRow) {
      const nextRowHeaders = nextRow.map(h => String(h || '').trim());
      
      console.log('\n=== 第2行内容 ===');
      nextRowHeaders.forEach((h, idx) => console.log(`  [${idx}] ${h}`));
      
      const hasSubHeaders = nextRowHeaders.some(h => 
        h && (h.includes('跳') || h.includes('节点') || h.includes('端口'))
      );
      
      console.log(`\n检测到子表头: ${hasSubHeaders}`);
      
      if (hasSubHeaders) {
        const mergedHeaders = [];
        for (let i = 0; i < Math.max(headers.length, nextRowHeaders.length); i++) {
          const header1 = headers[i] || '';
          const header2 = nextRowHeaders[i] || '';
          
          if (header2 && header2.trim() !== '') {
            mergedHeaders.push(header2);
          } else {
            mergedHeaders.push(header1);
          }
        }
        headers = mergedHeaders;
        
        console.log('\n=== 合并后的表头 ===');
        headers.forEach((h, idx) => console.log(`  [${idx}] ${h}`));
      }
    }
  }
  
  // 测试字段映射
  console.log('\n=== 字段映射测试 ===');
  const HEADER_MAPPINGS = {
    record_number: ['编号', '序号'],
    idc_requirement_number: ['IDC需求编号', 'IDC编号'],
    user_unit: ['用户', '用户单位'],
    cable_type: ['线缆类型', '线缆'],
    operator: ['运营商'],
    circuit_number: ['运营商编号', '线路编号'],
    contact_person: ['报障人', '联系人'],
    start_port: ['运营商端口', '起始端口'],
    hop1: ['一跳', '中间节点1'],
    hop2: ['二跳', '中间节点2'],
    hop3: ['三跳', '中间节点3'],
    hop4: ['四跳', '中间节点4'],
    hop5: ['五跳', '中间节点5'],
    end_port: ['目标端口']
  };
  
  const getValue = (row, headers, fieldNames) => {
    for (const fieldName of fieldNames) {
      const index = headers.findIndex(h => 
        h && (h === fieldName || h.includes(fieldName) || fieldName.includes(h))
      );
      if (index !== -1 && index < row.length) {
        return { index, value: row[index], fieldName };
      }
    }
    return null;
  };
  
  // 测试第3行数据（第一条数据记录）
  const dataRow = jsonData[2];
  console.log('\n=== 第3行数据（第一条记录）===');
  dataRow.forEach((col, idx) => console.log(`  [${idx}] ${col}`));
  
  console.log('\n=== 字段映射结果 ===');
  for (const [field, names] of Object.entries(HEADER_MAPPINGS)) {
    const result = getValue(dataRow, headers, names);
    if (result) {
      console.log(`  ${field}: [${result.index}] ${result.value} (匹配: ${result.fieldName})`);
    } else {
      console.log(`  ${field}: 未找到`);
    }
  }
  
} catch (error) {
  console.error('错误:', error.message);
  console.error(error.stack);
}
