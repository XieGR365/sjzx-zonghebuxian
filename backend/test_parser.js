const XLSX = require('xlsx');
const path = require('path');

const filePath = path.join(__dirname, '..', '01-原始素材', '参考资料', '_EXCEL', '金桥7号楼机房综合布线信息统计表20251219最新版.xlsx');

console.log('Reading file:', filePath);

try {
  const workbook = XLSX.readFile(filePath);
  const sheetNames = workbook.SheetNames;
  
  console.log('\nSheet names:', sheetNames);
  
  let totalRows = 0;
  
  sheetNames.forEach(name => {
    const sheet = workbook.Sheets[name];
    const data = XLSX.utils.sheet_to_json(sheet);
    console.log(`\nSheet '${name}' has ${data.length} rows`);
    totalRows += data.length;
    
    if (data.length > 0) {
      console.log('First row:', JSON.stringify(data[0], null, 2));
    }
  });
  
  console.log(`\nTotal rows across all sheets: ${totalRows}`);
} catch (error) {
  console.error('Error:', error);
}
