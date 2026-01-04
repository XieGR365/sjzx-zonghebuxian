const XLSX = require('xlsx');
const path = require('path');

const filePath = path.join(__dirname, '..', '01-原始素材', '参考资料', '_EXCEL', '金桥7号楼机房综合布线信息统计表20251219最新版.xlsx');

console.log('Reading file:', filePath);

try {
  const workbook = XLSX.readFile(filePath);
  const sheetNames = workbook.SheetNames;
  
  const HEADER_MAPPINGS = {
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

  const findHeaderRow = (data) => {
    let maxMatchCount = 0;
    let headerRowIndex = 0;

    for (let i = 0; i < Math.min(5, data.length); i++) {
      const row = data[i];
      if (!row) continue;

      const rowHeaders = row.map(h => String(h || '').trim());
      let matchCount = 0;

      Object.values(HEADER_MAPPINGS).forEach(expectedHeaders => {
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

    console.log(`Header row index: ${headerRowIndex}, Match count: ${maxMatchCount}`);
    return headerRowIndex;
  };

  sheetNames.forEach(name => {
    console.log(`\n=== Sheet '${name}' ===`);
    const sheet = workbook.Sheets[name];
    const rawData = XLSX.utils.sheet_to_json(sheet, { header: 1, blankrows: false });
    
    console.log(`Total rows (including header): ${rawData.length}`);
    
    const headerRowIndex = findHeaderRow(rawData);
    console.log(`Header row content:`, JSON.stringify(rawData[headerRowIndex], null, 2));
    
    if (headerRowIndex + 1 < rawData.length) {
      const nextRow = rawData[headerRowIndex + 1];
      const nextRowHeaders = nextRow.map(h => String(h || '').trim());
      const hasSubHeaders = nextRowHeaders.some(h => 
        h && (h.includes('跳') || h.includes('节点') || h.includes('端口'))
      );
      console.log(`Has sub headers: ${hasSubHeaders}`);
      if (hasSubHeaders) {
        console.log(`Sub header row content:`, JSON.stringify(nextRow, null, 2));
      }
    }
  });
} catch (error) {
  console.error('Error:', error);
}
