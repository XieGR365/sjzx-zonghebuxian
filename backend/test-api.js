const fs = require('fs');
const path = require('path');
const FormData = require('form-data');
const http = require('http');

const BASE_URL = 'http://localhost:3001';

async function testUpload() {
  return new Promise((resolve, reject) => {
    const filePath = path.join(__dirname, '../../05-测试/测试数据.xlsx');
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
        resolve({
          statusCode: res.statusCode,
          body: JSON.parse(data)
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    form.pipe(req);
  });
}

async function testQuery() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: '/api/records/query',
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: JSON.parse(data)
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
}

async function testGetDatacenters() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: '/api/records/datacenters',
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: JSON.parse(data)
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
}

async function testGetFilterOptions() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: '/api/records/filter-options',
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: JSON.parse(data)
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
}

async function testClearAll() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: '/api/records/clear',
      method: 'DELETE'
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: JSON.parse(data)
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
}

async function runTests() {
  console.log('='.repeat(60));
  console.log('综合布线记录管理系统 - API测试');
  console.log('='.repeat(60));
  console.log();

  const results = [];

  console.log('测试1: 清空数据库');
  try {
    const result = await testClearAll();
    console.log(`状态码: ${result.statusCode}`);
    console.log(`响应: ${JSON.stringify(result.body, null, 2)}`);
    results.push({
      test: '清空数据库',
      status: result.statusCode === 200 ? '通过' : '失败',
      statusCode: result.statusCode,
      response: result.body
    });
  } catch (error) {
    console.error('错误:', error.message);
    results.push({
      test: '清空数据库',
      status: '失败',
      error: error.message
    });
  }
  console.log();

  console.log('测试2: 上传Excel文件');
  try {
    const result = await testUpload();
    console.log(`状态码: ${result.statusCode}`);
    console.log(`响应: ${JSON.stringify(result.body, null, 2)}`);
    results.push({
      test: '上传Excel文件',
      status: result.statusCode === 200 ? '通过' : '失败',
      statusCode: result.statusCode,
      response: result.body
    });
  } catch (error) {
    console.error('错误:', error.message);
    results.push({
      test: '上传Excel文件',
      status: '失败',
      error: error.message
    });
  }
  console.log();

  console.log('测试3: 查询所有记录');
  try {
    const result = await testQuery();
    console.log(`状态码: ${result.statusCode}`);
    console.log(`响应: ${JSON.stringify(result.body, null, 2)}`);
    results.push({
      test: '查询所有记录',
      status: result.statusCode === 200 ? '通过' : '失败',
      statusCode: result.statusCode,
      response: result.body
    });
  } catch (error) {
    console.error('错误:', error.message);
    results.push({
      test: '查询所有记录',
      status: '失败',
      error: error.message
    });
  }
  console.log();

  console.log('测试4: 获取机房列表');
  try {
    const result = await testGetDatacenters();
    console.log(`状态码: ${result.statusCode}`);
    console.log(`响应: ${JSON.stringify(result.body, null, 2)}`);
    results.push({
      test: '获取机房列表',
      status: result.statusCode === 200 ? '通过' : '失败',
      statusCode: result.statusCode,
      response: result.body
    });
  } catch (error) {
    console.error('错误:', error.message);
    results.push({
      test: '获取机房列表',
      status: '失败',
      error: error.message
    });
  }
  console.log();

  console.log('测试5: 获取筛选选项');
  try {
    const result = await testGetFilterOptions();
    console.log(`状态码: ${result.statusCode}`);
    console.log(`响应: ${JSON.stringify(result.body, null, 2)}`);
    results.push({
      test: '获取筛选选项',
      status: result.statusCode === 200 ? '通过' : '失败',
      statusCode: result.statusCode,
      response: result.body
    });
  } catch (error) {
    console.error('错误:', error.message);
    results.push({
      test: '获取筛选选项',
      status: '失败',
      error: error.message
    });
  }
  console.log();

  console.log('='.repeat(60));
  console.log('测试总结');
  console.log('='.repeat(60));
  const passed = results.filter(r => r.status === '通过').length;
  const failed = results.filter(r => r.status === '失败').length;
  console.log(`总测试数: ${results.length}`);
  console.log(`通过: ${passed}`);
  console.log(`失败: ${failed}`);
  console.log();

  fs.writeFileSync(
    path.join(__dirname, '../../05-测试/test-results.json'),
    JSON.stringify(results, null, 2)
  );
  console.log('测试结果已保存到: test-results.json');
}

runTests().catch(console.error);
