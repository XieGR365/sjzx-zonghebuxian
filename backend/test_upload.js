const FormData = require('form-data');
const fs = require('fs');
const http = require('http');

const filePath = 'd:\\TREA\\sjzx-zonghebuxian\\01-原始素材\\参考资料\\_EXCEL\\金桥7号楼机房综合布线信息统计表20251219最新版.xlsx';

const form = new FormData();
form.append('file', fs.createReadStream(filePath));

const options = {
  hostname: 'localhost',
  port: 3001,
  path: '/api/records/upload',
  method: 'POST',
  headers: form.getHeaders()
};

const req = http.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', data);
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

form.pipe(req);
