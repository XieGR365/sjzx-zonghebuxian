const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');

// 配置
const API_BASE_URL = 'http://localhost:3001/api';
const EXCEL_DIR = 'd:\\TREA\\sjzx-zonghebuxian\\01-原始素材\\参考资料\\_EXCEL';
const TEST_REPORT_PATH = 'd:\\TREA\\sjzx-zonghebuxian\\05-测试\\测试报告';

// 确保测试报告目录存在
if (!fs.existsSync(TEST_REPORT_PATH)) {
    fs.mkdirSync(TEST_REPORT_PATH, { recursive: true });
}

// 获取所有Excel文件
const excelFiles = fs.readdirSync(EXCEL_DIR)
    .filter(file => file.endsWith('.xlsx'))
    .map(file => path.join(EXCEL_DIR, file));

// 测试单个Excel文件的详细上传
async function testSingleExcelUpload(filePath) {
    console.log('\n' + '='.repeat(80));
    console.log(`详细测试: 上传Excel文件 - ${path.basename(filePath)}`);
    console.log('='.repeat(80));
    
    try {
        const formData = new FormData();
        formData.append('file', fs.createReadStream(filePath));
        
        const response = await axios.post(`${API_BASE_URL}/records/upload`, formData, {
            headers: {
                ...formData.getHeaders(),
            },
            maxContentLength: Infinity,
            maxBodyLength: Infinity
        });
        
        console.log(`状态码: ${response.status}`);
        console.log(`响应: ${JSON.stringify(response.data, null, 2)}`);
        console.log('\n' + '='.repeat(80));
        return { success: true, response: response.data };
        
    } catch (error) {
        console.log(`请求失败，状态码: ${error.response?.status || 'N/A'}`);
        console.log(`错误信息: ${error.message}`);
        if (error.response?.data) {
            console.log(`响应数据: ${JSON.stringify(error.response.data, null, 2)}`);
        }
        console.log('\n' + '='.repeat(80));
        return { success: false, error: error.response?.data || error.message };
    }
}

// 主函数
async function runDetailedTests() {
    console.log('综合布线记录管理系统 - 详细Excel测试');
    console.log('测试时间:', new Date().toISOString());
    console.log('测试文件数量:', excelFiles.length);
    
    // 先清空数据库
    try {
        const clearResponse = await axios.delete(`${API_BASE_URL}/records/clear`);
        console.log('\n清空数据库结果:', clearResponse.data);
    } catch (error) {
        console.log('清空数据库失败:', error.message);
    }
    
    // 测试每个Excel文件
    for (const file of excelFiles) {
        await testSingleExcelUpload(file);
    }
    
    console.log('\n所有测试完成!');
}

runDetailedTests().catch(error => {
    console.error('测试过程中发生错误:', error);
    process.exit(1);
});
