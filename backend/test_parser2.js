const XLSX = require('xlsx');
const path = require('path');

const filePath = path.join(__dirname, '..', '01-原始素材', '参考资料', '_EXCEL', '金桥7号楼机房综合布线信息统计表20251219最新版.xlsx');

console.log('Reading file:', filePath);

try {
  const workbook = XLSX.readFile(filePath);
  const sheetNames = workbook.SheetNames;
  
  console.log('\nSheet names:', sheetNames);
  
  sheetNames.forEach(name => {
    console.log(`\n=== Sheet '${name}' ===`);
    const sheet = workbook.Sheets[name];
    
    // 使用 header: 1 来获取原始数组格式
    const rawData = XLSX.utils.sheet_to_json(sheet, { header: 1 });
    
    console.log(`\nTotal rows (including header): ${rawData.length}`);
    
    // 显示前5行
    console.log('\nFirst 5 rows:');
    for (let i = 0; i < Math.min(5, rawData.length); i++) {
      console.log(`Row ${i + 1}:`, JSON.stringify(rawData[i], null, 2));
    }
  });
} catch (error) {
  console.error('Error:', error);
}
