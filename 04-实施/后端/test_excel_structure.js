const xlsx = require('xlsx');
const path = require('path');

const filePath = path.join(__dirname, '../01-原始素材/参考资料/_EXCEL/金桥7号楼机房综合布线信息统计表20251219最新版.xlsx');

console.log('正在分析Excel文件结构...\n');

try {
  const workbook = xlsx.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  const jsonData = xlsx.utils.sheet_to_json(worksheet, { header: 1 });

  console.log('总行数:', jsonData.length);
  console.log('总列数:', jsonData[0] ? jsonData[0].length : 0);
  console.log('\n前10行数据:\n');

  for (let i = 0; i < Math.min(10, jsonData.length); i++) {
    const row = jsonData[i];
    console.log(`第${i + 1}行:`, row.map((cell, idx) => `[${idx}]${cell || '(空)'}`).join(' | '));
  }

  console.log('\n\n分析表头结构...\n');

  const headerRows = [];
  for (let i = 0; i < Math.min(5, jsonData.length); i++) {
    const row = jsonData[i];
    if (row && row.some(cell => cell)) {
      headerRows.push(row);
    }
  }

  console.log('可能的表头行数:', headerRows.length);
  console.log('\n表头内容:');
  headerRows.forEach((row, idx) => {
    console.log(`第${idx + 1}行:`, row.map((cell, colIdx) => `[列${colIdx}]${cell || '(空)'}`).join(' | '));
  });

  console.log('\n\n分析数据行...\n');

  const dataStartRow = headerRows.length;
  console.log('数据起始行:', dataStartRow + 1);

  let dataRowCount = 0;
  let emptyRowCount = 0;
  for (let i = dataStartRow; i < jsonData.length; i++) {
    const row = jsonData[i];
    if (!row || row.length === 0) {
      emptyRowCount++;
      continue;
    }

    const hasData = row.some(cell => cell !== undefined && cell !== null && cell !== '');
    if (hasData) {
      dataRowCount++;
    } else {
      emptyRowCount++;
    }
  }

  console.log('数据行数:', dataRowCount);
  console.log('空行数:', emptyRowCount);

  console.log('\n\n分析列名...\n');

  if (headerRows.length > 0) {
    const maxCols = Math.max(...headerRows.map(row => row.length));
    console.log('最大列数:', maxCols);

    for (let col = 0; col < maxCols; col++) {
      const columnData = [];
      for (let row = 0; row < headerRows.length; row++) {
        const cell = headerRows[row][col];
        if (cell) {
          columnData.push(cell);
        }
      }
      if (columnData.length > 0) {
        console.log(`列${col}:`, columnData.join(' -> '));
      }
    }
  }

  console.log('\n\n分析数据样本...\n');

  let sampleCount = 0;
  for (let i = dataStartRow; i < jsonData.length && sampleCount < 5; i++) {
    const row = jsonData[i];
    if (!row || row.length === 0) continue;

    const hasData = row.some(cell => cell !== undefined && cell !== null && cell !== '');
    if (hasData) {
      console.log(`数据样本${sampleCount + 1} (第${i + 1}行):`);
      row.forEach((cell, idx) => {
        if (cell !== undefined && cell !== null && cell !== '') {
          console.log(`  [列${idx}] ${cell}`);
        }
      });
      console.log();
      sampleCount++;
    }
  }

} catch (error) {
  console.error('错误:', error.message);
  console.error(error.stack);
}
