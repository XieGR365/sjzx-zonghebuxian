const xlsx = require('xlsx');
const path = require('path');

const filePath = path.join(__dirname, '../../01-原始素材/参考资料/_EXCEL/金桥7号楼机房综合布线信息统计表20251219最新版.xlsx');

console.log('正在分析Excel文件中执行时间字段的格式...\n');

try {
  const workbook = xlsx.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  const jsonData = xlsx.utils.sheet_to_json(worksheet, { header: 1 });

  console.log('前10行数据:\n');

  for (let i = 0; i < Math.min(10, jsonData.length); i++) {
    const row = jsonData[i];
    console.log(`第${i + 1}行:`, row.map((cell, idx) => `[${idx}]${cell || '(空)'}`).join(' | '));
  }

  console.log('\n\n查找执行时间相关列...\n');

  const headerRows = [];
  for (let i = 0; i < Math.min(5, jsonData.length); i++) {
    const row = jsonData[i];
    if (row && row.some(cell => cell)) {
      headerRows.push(row);
    }
  }

  const dataStartRow = headerRows.length;

  for (let col = 0; col < 20; col++) {
    const headerCell = headerRows[0] ? headerRows[0][col] : '';
    if (headerCell && (headerCell.includes('执行') || headerCell.includes('时间') || headerCell.includes('日期'))) {
      console.log(`列${col} 表头:`, headerCell);
      
      let sampleCount = 0;
      for (let i = dataStartRow; i < jsonData.length && sampleCount < 5; i++) {
        const row = jsonData[i];
        if (row && row[col] !== undefined && row[col] !== null && row[col] !== '') {
          console.log(`  数据样本${sampleCount + 1} (第${i + 1}行):`, row[col], `(类型: ${typeof row[col]})`);
          sampleCount++;
        }
      }
      console.log();
    }
  }

} catch (error) {
  console.error('错误:', error.message);
  console.error(error.stack);
}
