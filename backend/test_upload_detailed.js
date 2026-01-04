const FormData = require('form-data');
const fs = require('fs');
const http = require('http');

const filePath = 'd:\\TREA\\sjzx-zonghebuxian\\01-原始素材\\参考资料\\_EXCEL\\金桥7号楼机房综合布线信息统计表20251219最新版.xlsx';

console.log('Testing upload with different file sizes and configurations...');

const testUpload = (filePath) => {
  return new Promise((resolve, reject) => {
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
        console.log('Headers:', JSON.stringify(res.headers, null, 2));
        console.log('Response:', data);
        
        try {
          const response = JSON.parse(data);
          resolve(response);
        } catch (e) {
          resolve({ raw: data });
        }
      });
    });

    req.on('error', (error) => {
      console.error('Error:', error);
      reject(error);
    });

    form.pipe(req);
  });
};

testUpload(filePath)
  .then(result => {
    console.log('\n✅ Upload test completed successfully!');
    console.log('Result:', JSON.stringify(result, null, 2));
  })
  .catch(error => {
    console.error('\n❌ Upload test failed!');
    console.error('Error:', error);
  });
