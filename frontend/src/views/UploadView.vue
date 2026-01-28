<template>
  <div class="upload-view">
    <el-card class="upload-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <el-icon :size="20" color="#409EFF"><Upload /></el-icon>
          <span>上传布线记录文件</span>
        </div>
      </template>

      <div class="upload-content">
        <el-upload
          ref="uploadRef"
          class="upload-area"
          drag
          :auto-upload="false"
          :on-change="handleFileChange"
          :limit="1"
          accept=".xlsx,.xls"
          :file-list="fileList"
        >
          <el-icon class="upload-icon" :size="60"><UploadFilled /></el-icon>
          <div class="upload-text">
            <p class="primary-text">将Excel文件拖到此处，或点击上传</p>
            <p class="secondary-text">支持 .xlsx 和 .xls 格式，文件大小不超过 10MB</p>
          </div>
        </el-upload>

        <div v-if="selectedFile" class="file-info">
          <el-alert
            :title="`已选择文件: ${selectedFile.name}`"
            type="info"
            :closable="false"
            show-icon
          >
            <template #default>
              <div class="file-details">
                <span>文件大小: {{ formatFileSize(selectedFile.size) }}</span>
              </div>
            </template>
          </el-alert>
        </div>

        <div class="upload-actions">
          <el-button
            type="primary"
            size="large"
            :loading="uploading"
            :disabled="!selectedFile"
            @click="handleUpload"
          >
            <el-icon><Upload /></el-icon>
            上传并解析
          </el-button>
          <el-button size="large" @click="handleClear">
            <el-icon><Delete /></el-icon>
            清空
          </el-button>
        </div>
      </div>
    </el-card>

    <el-card v-if="uploadResult" class="result-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <el-icon :size="20" color="#67C23A"><CircleCheck /></el-icon>
          <span>上传结果</span>
        </div>
      </template>
      <el-result
        :icon="uploadResult.success ? 'success' : 'error'"
        :title="uploadResult.success ? '上传成功' : '上传失败'"
        :sub-title="uploadResult.message"
      >
        <template v-if="uploadResult.success && uploadResult.data" #extra>
          <div class="statistics-container">
            <el-row :gutter="20">
              <el-col :span="12">
                <el-statistic title="新增记录数" :value="uploadResult.data.insertedCount">
                  <template #suffix>条</template>
                </el-statistic>
              </el-col>
              <el-col :span="12">
                <el-statistic title="更新记录数" :value="uploadResult.data.updatedCount">
                  <template #suffix>条</template>
                </el-statistic>
              </el-col>
            </el-row>
          </div>
          <el-button type="primary" @click="goToRecords">
            查看记录列表
            <el-icon class="el-icon--right"><ArrowRight /></el-icon>
          </el-button>
        </template>
      </el-result>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { Upload, UploadFilled, Delete, CircleCheck, ArrowRight } from '@element-plus/icons-vue';
import { recordApi } from '@/services/api';
import type { UploadFile, UploadUserFile } from 'element-plus';

const router = useRouter();
const uploadRef = ref();
const fileList = ref<UploadUserFile[]>([]);
const selectedFile = ref<File | null>(null);
const uploading = ref(false);
const uploadResult = ref<{
  success: boolean;
  message: string;
  data?: {
    insertedCount: number;
    updatedCount: number;
    insertedIds: number[];
    updatedIds: number[];
  };
} | null>(null);

const handleFileChange = (file: UploadFile) => {
  if (file.raw) {
    selectedFile.value = file.raw;
    uploadResult.value = null;
  }
};

const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
};

const handleUpload = async () => {
  if (!selectedFile.value) {
    ElMessage.warning('请先选择文件');
    return;
  }

  uploading.value = true;
  uploadResult.value = null;

  try {
    const response = await recordApi.upload(selectedFile.value);
    uploadResult.value = {
      success: response.success,
      message: response.message || '上传成功',
      data: response.data,
    };

    if (response.success) {
      ElMessage.success(response.message || '上传成功');
    } else {
      ElMessage.error(response.message || '上传失败');
    }
  } catch (error: any) {
    uploadResult.value = {
      success: false,
      message: error.response?.data?.message || '上传失败，请稍后重试',
    };
    ElMessage.error(error.response?.data?.message || '上传失败，请稍后重试');
  } finally {
    uploading.value = false;
  }
};

const handleClear = () => {
  fileList.value = [];
  selectedFile.value = null;
  uploadResult.value = null;
  uploadRef.value?.clearFiles();
};

const goToRecords = () => {
  router.push('/records');
};
</script>

<style scoped>
.upload-view {
  width: 100%;
  max-width: 800px;
  margin: 0 auto;
}

.upload-card {
  border-radius: 16px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.upload-content {
  padding: 20px 0;
}

.upload-area {
  margin-bottom: 24px;
}

:deep(.el-upload-dragger) {
  padding: 60px 20px;
  border: 2px dashed #dcdfe6;
  border-radius: 12px;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  transition: all 0.3s ease;
}

:deep(.el-upload-dragger:hover) {
  border-color: #409eff;
  background: linear-gradient(135deg, #ecf5ff 0%, #ffffff 100%);
}

.upload-icon {
  color: #409eff;
  margin-bottom: 16px;
}

.upload-text {
  text-align: center;
}

.primary-text {
  font-size: 16px;
  color: #303133;
  margin-bottom: 8px;
  font-weight: 500;
}

.secondary-text {
  font-size: 14px;
  color: #909399;
}

.file-info {
  margin-bottom: 24px;
}

.file-details {
  margin-top: 8px;
  font-size: 14px;
  color: #606266;
}

.upload-actions {
  display: flex;
  gap: 12px;
  justify-content: center;
}

.result-card {
  margin-top: 24px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
}

:deep(.el-result) {
  padding: 40px 0;
}

:deep(.el-statistic) {
  margin-bottom: 24px;
}

:deep(.el-statistic__head) {
  font-size: 14px;
  color: #909399;
}

:deep(.el-statistic__number) {
  font-size: 36px;
  font-weight: 600;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.statistics-container {
  margin-bottom: 24px;
  padding: 20px;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  border-radius: 12px;
}

:deep(.el-row) {
  margin: 0 !important;
}

:deep(.el-col) {
  padding: 0 !important;
}
</style>
