const xlsx = require('xlsx');
const path = require('path');
const { ExcelParser } = require('./dist/services/ExcelParser.js');

const filePath = path.join(__dirname, '../../01-原始素材/参考资料/_EXCEL/金桥7号楼机房综合布线信息统计表20251219最新版.xlsx');

console.log('正在测试ExcelParser解析后的日期格式...\n');

try {
  const fs = require('fs');
  const buffer = fs.readFileSync(filePath);
  
  const result = ExcelParser.parse(buffer);
  
  console.log(`解析成功！共解析 ${result.records.length} 条记录\n`);
  
  if (result.records.length > 0) {
    console.log('前5条记录的执行时间字段:\n');
    for (let i = 0; i < Math.min(5, result.records.length); i++) {
      const record = result.records[i];
      console.log(`记录 ${i + 1}:`);
      console.log(`  登记表编号: ${record.record_number}`);
      console.log(`  执行时间: ${record.execution_date} (类型: ${typeof record.execution_date})`);
      console.log();
    }
  }
  
  if (result.errors.length > 0) {
    console.log('\n解析错误:');
    result.errors.forEach((error, index) => {
      console.log(`${index + 1}. ${error}`);
    });
  }
  
} catch (error) {
  console.error('错误:', error.message);
  console.error(error.stack);
}
