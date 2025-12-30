const xlsx = require('xlsx');
const path = require('path');

const filePath = path.join(__dirname, '../../01-原始素材/参考资料/_EXCEL/金桥7号楼机房综合布线信息统计表20251219最新版.xlsx');

console.log('正在分析Excel文件中执行时间字段的详细格式...\n');

try {
  const workbook = xlsx.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  const jsonData = xlsx.utils.sheet_to_json(worksheet, { header: 1, raw: false, dateNF: 'yyyy-mm-dd' });

  console.log('执行时间列（第2列）的数据样本:\n');

  const executionDates = [];
  for (let i = 2; i < Math.min(15, jsonData.length); i++) {
    const row = jsonData[i];
    if (row && row[2]) {
      executionDates.push({
        row: i + 1,
        value: row[2],
        type: typeof row[2]
      });
    }
  }

  console.log('Excel中显示的格式（raw: false）:');
  executionDates.forEach(item => {
    console.log(`  第${item.row}行: ${item.value} (类型: ${item.type})`);
  });

  console.log('\n\n使用原始数据格式（raw: true）:');
  const jsonDataRaw = xlsx.utils.sheet_to_json(worksheet, { header: 1, raw: true });
  
  const executionDatesRaw = [];
  for (let i = 2; i < Math.min(15, jsonDataRaw.length); i++) {
    const row = jsonDataRaw[i];
    if (row && row[2] !== undefined && row[2] !== null && row[2] !== '') {
      executionDatesRaw.push({
        row: i + 1,
        value: row[2],
        type: typeof row[2]
      });
    }
  }

  executionDatesRaw.forEach(item => {
    console.log(`  第${item.row}行: ${item.value} (类型: ${item.type})`);
  });

  console.log('\n\n将Excel日期序列号转换为标准日期:');
  executionDatesRaw.forEach(item => {
    if (typeof item.value === 'number') {
      const date = new Date((item.value - 25569) * 86400 * 1000);
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      console.log(`  序列号 ${item.value} -> ${year}-${month}-${day}`);
    }
  });

  console.log('\n\n检查Excel单元格的原始格式:');
  const cellAddress = 'C3';
  const cell = worksheet[cellAddress];
  if (cell) {
    console.log(`  单元格 ${cellAddress}:`);
    console.log(`    原始值: ${cell.v}`);
    console.log(`    显示值: ${cell.w}`);
    console.log(`    类型: ${cell.t}`);
    console.log(`    格式代码: ${cell.z}`);
  }

} catch (error) {
  console.error('错误:', error.message);
  console.error(error.stack);
}
