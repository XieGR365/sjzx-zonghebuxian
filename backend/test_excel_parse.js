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

  console.log('工作表名称:', workbook.SheetNames);
  
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  
  const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1, blankrows: false });
  
  console.log('\n总行数:', jsonData.length);
  console.log('\n前10行数据:');
  
  for (let i = 0; i < Math.min(10, jsonData.length); i++) {
    console.log(`\n第${i + 1}行 (${jsonData[i].length}列):`);
    console.log(jsonData[i]);
  }
  
  console.log('\n第1行作为表头:');
  const headers = jsonData[0].map(h => String(h || '').trim());
  console.log(headers);
  
} catch (error) {
  console.error('错误:', error.message);
  console.error(error.stack);
}
