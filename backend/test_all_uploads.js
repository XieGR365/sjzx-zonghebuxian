const FormData = require('form-data');
const fs = require('fs');
const http = require('http');
const path = require('path');

const excelDir = 'd:\\TREA\\sjzx-zonghebuxian\\01-原始素材\\参考资料\\_EXCEL';

const excelFiles = fs.readdirSync(excelDir).filter(file => 
  file.endsWith('.xlsx') && !file.startsWith('~$')
);

console.log(`Found ${excelFiles.length} Excel files to test:\n`);

const testUpload = (filePath, fileName) => {
  return new Promise((resolve, reject) => {
    console.log(`\n📤 Testing: ${fileName}`);
    console.log(`   Path: ${filePath}`);
    
    if (!fs.existsSync(filePath)) {
      console.log(`   ❌ File not found!`);
      resolve({ fileName, success: false, error: 'File not found' });
      return;
    }

    const stats = fs.statSync(filePath);
    console.log(`   Size: ${(stats.size / 1024).toFixed(2)} KB`);

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
        console.log(`   Status: ${res.statusCode}`);
        
        try {
          const response = JSON.parse(data);
          if (response.success) {
            console.log(`   ✅ Success: ${response.message}`);
            console.log(`   📊 Records imported: ${response.data?.count || 0}`);
          } else {
            console.log(`   ❌ Failed: ${response.message}`);
            if (response.details) {
              console.log(`   Details: ${JSON.stringify(response.details)}`);
            }
          }
          resolve({ fileName, ...response });
        } catch (e) {
          console.log(`   ❌ Parse error: ${e.message}`);
          console.log(`   Raw response: ${data.substring(0, 200)}...`);
          resolve({ fileName, success: false, error: 'Parse error', raw: data });
        }
      });
    });

    req.on('error', (error) => {
      console.log(`   ❌ Request error: ${error.message}`);
      resolve({ fileName, success: false, error: error.message });
    });

    form.pipe(req);
  });
};

const runTests = async () => {
  const results = [];
  
  for (const file of excelFiles) {
    const filePath = path.join(excelDir, file);
    const result = await testUpload(filePath, file);
    results.push(result);
    
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  console.log('\n\n' + '='.repeat(80));
  console.log('📊 TEST SUMMARY');
  console.log('='.repeat(80));
  
  const successCount = results.filter(r => r.success).length;
  const failCount = results.filter(r => !r.success).length;
  
  console.log(`\nTotal files tested: ${results.length}`);
  console.log(`✅ Successful: ${successCount}`);
  console.log(`❌ Failed: ${failCount}`);
  
  if (failCount > 0) {
    console.log('\n❌ Failed files:');
    results.filter(r => !r.success).forEach(r => {
      console.log(`   - ${r.fileName}: ${r.error || r.message || 'Unknown error'}`);
    });
  }
  
  console.log('\n✅ Successful files:');
  results.filter(r => r.success).forEach(r => {
    console.log(`   - ${r.fileName}: ${r.data?.count || 0} records`);
  });
};

runTests().catch(console.error);
