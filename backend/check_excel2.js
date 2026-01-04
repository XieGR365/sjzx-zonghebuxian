const XLSX = require('xlsx');
const path = require('path');

const excelPath = path.join(__dirname, '../01-原始素材/参考资料/_EXCEL/临港二期数据中心线路登记表20251212最新版.xlsx');
const workbook = XLSX.readFile(excelPath);
const sheetName = workbook.SheetNames[0];
const sheet = workbook.Sheets[sheetName];

const jsonData = XLSX.utils.sheet_to_json(sheet, { header: 1 });

console.log('Excel 表头（带索引）:');
jsonData[0].forEach((header, index) => {
  console.log(`[${index}]: ${header}`);
});

console.log('\n前10行数据（只显示用户名称和报障人/联系方式列）:');
for (let i = 1; i < Math.min(11, jsonData.length); i++) {
  const row = jsonData[i];
  console.log(`行 ${i}: 用户名称[${5}]: ${row[5]}, 报障人/联系方式[${9}]: ${row[9]}`);
}
