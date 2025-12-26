<template>
  <div class="detail-view">
    <el-card class="detail-card" shadow="hover" v-loading="loading">
      <template #header>
        <div class="card-header">
          <el-button link @click="goBack">
            <el-icon><ArrowLeft /></el-icon>
            返回
          </el-button>
          <el-icon :size="20" color="#409EFF"><Document /></el-icon>
          <span>布线记录详情</span>
        </div>
      </template>

      <template v-if="record">
        <div class="detail-content">
          <div class="detail-section">
            <h3 class="section-title">
              <el-icon><InfoFilled /></el-icon>
              基本信息
            </h3>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="登记表编号" :span="2">
                <el-tag type="primary">{{ record.record_number }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="机房名称">
                <el-tag type="success">{{ record.datacenter_name }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="用户单位">
                {{ record.user_unit || '-' }}
              </el-descriptions-item>
              <el-descriptions-item label="IDC需求编号">
                {{ record.idc_requirement_number || '-' }}
              </el-descriptions-item>
              <el-descriptions-item label="YES工单编号">
                {{ record.yes_ticket_number || '-' }}
              </el-descriptions-item>
            </el-descriptions>
          </div>

          <div class="detail-section">
            <h3 class="section-title">
              <el-icon><Connection /></el-icon>
              线路信息
            </h3>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="线路编号" :span="2">
                <el-tag type="info">{{ record.circuit_number || '-' }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="线缆类型">
                {{ record.cable_type || '-' }}
              </el-descriptions-item>
              <el-descriptions-item label="运营商">
                {{ record.operator || '-' }}
              </el-descriptions-item>
              <el-descriptions-item label="报障人/联系方式" :span="2">
                {{ record.contact_person || '-' }}
              </el-descriptions-item>
            </el-descriptions>
          </div>

          <div class="detail-section">
            <h3 class="section-title">
              <el-icon><Position /></el-icon>
              端口信息
            </h3>
            <div class="port-path">
              <div class="port-node">
                <div class="port-label">起始端口（A端）</div>
                <div class="port-value">{{ record.start_port || '-' }}</div>
              </div>
              <div class="port-arrow">
                <el-icon><ArrowRight /></el-icon>
              </div>
              <div class="port-node" v-if="record.hop1">
                <div class="port-label">一跳</div>
                <div class="port-value">{{ record.hop1 }}</div>
              </div>
              <div class="port-arrow" v-if="record.hop1">
                <el-icon><ArrowRight /></el-icon>
              </div>
              <div class="port-node" v-if="record.hop2">
                <div class="port-label">二跳</div>
                <div class="port-value">{{ record.hop2 }}</div>
              </div>
              <div class="port-arrow" v-if="record.hop2">
                <el-icon><ArrowRight /></el-icon>
              </div>
              <div class="port-node" v-if="record.hop3">
                <div class="port-label">三跳</div>
                <div class="port-value">{{ record.hop3 }}</div>
              </div>
              <div class="port-arrow" v-if="record.hop3">
                <el-icon><ArrowRight /></el-icon>
              </div>
              <div class="port-node" v-if="record.hop4">
                <div class="port-label">四跳</div>
                <div class="port-value">{{ record.hop4 }}</div>
              </div>
              <div class="port-arrow" v-if="record.hop4">
                <el-icon><ArrowRight /></el-icon>
              </div>
              <div class="port-node" v-if="record.hop5">
                <div class="port-label">五跳</div>
                <div class="port-value">{{ record.hop5 }}</div>
              </div>
              <div class="port-arrow" v-if="record.hop5">
                <el-icon><ArrowRight /></el-icon>
              </div>
              <div class="port-node">
                <div class="port-label">目标端口（Z端）</div>
                <div class="port-value">{{ record.end_port || '-' }}</div>
              </div>
            </div>
          </div>

          <div class="detail-section">
            <h3 class="section-title">
              <el-icon><OfficeBuilding /></el-icon>
              机柜信息
            </h3>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="用户机柜">
                <el-tag type="warning">{{ record.user_cabinet || '-' }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="线路标签是否齐全">
                <el-tag :type="record.label_complete ? 'success' : 'danger'">
                  {{ record.label_complete ? '是' : '否' }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="线路是否规范" :span="2">
                <el-tag :type="record.cable_standard ? 'success' : 'danger'">
                  {{ record.cable_standard ? '是' : '否' }}
                </el-tag>
              </el-descriptions-item>
            </el-descriptions>
          </div>

          <div class="detail-section" v-if="record.remark">
            <h3 class="section-title">
              <el-icon><ChatDotRound /></el-icon>
              备注
            </h3>
            <div class="remark-content">
              {{ record.remark }}
            </div>
          </div>

          <div class="detail-section">
            <h3 class="section-title">
              <el-icon><Clock /></el-icon>
              时间信息
            </h3>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="创建时间">
                {{ formatDate(record.created_at) }}
              </el-descriptions-item>
              <el-descriptions-item label="更新时间">
                {{ formatDate(record.updated_at) }}
              </el-descriptions-item>
            </el-descriptions>
          </div>
        </div>
      </template>

      <el-empty v-else description="记录不存在" />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { ElMessage } from 'element-plus';
import {
  ArrowLeft,
  Document,
  InfoFilled,
  Connection,
  Position,
  ArrowRight,
  OfficeBuilding,
  ChatDotRound,
  Clock
} from '@element-plus/icons-vue';
import { recordApi } from '@/services/api';
import type { Record } from '@/types';

const router = useRouter();
const route = useRoute();

const record = ref<Record | null>(null);
const loading = ref(false);

const loadRecord = async () => {
  const id = parseInt(route.params.id as string);
  if (isNaN(id)) {
    ElMessage.error('无效的记录ID');
    goBack();
    return;
  }

  loading.value = true;
  try {
    const response = await recordApi.getDetail(id);
    if (response.success && response.data) {
      record.value = response.data;
    } else {
      ElMessage.error('记录不存在');
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || '获取记录详情失败');
  } finally {
    loading.value = false;
  }
};

const goBack = () => {
  router.back();
};

const formatDate = (dateStr: string | undefined) => {
  if (!dateStr) return '-';
  const date = new Date(dateStr);
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
};

onMounted(() => {
  loadRecord();
});
</script>

<style scoped>
.detail-view {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
}

.detail-card {
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

.detail-content {
  padding: 20px 0;
}

.detail-section {
  margin-bottom: 32px;
}

.detail-section:last-child {
  margin-bottom: 0;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 600;
  color: #409EFF;
  margin-bottom: 16px;
  padding-bottom: 8px;
  border-bottom: 2px solid #e4e7ed;
}

.port-path {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  padding: 20px;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  border-radius: 12px;
  border: 1px solid #e4e7ed;
}

.port-node {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  min-width: 120px;
}

.port-label {
  font-size: 12px;
  color: #909399;
  font-weight: 500;
}

.port-value {
  padding: 8px 16px;
  background: white;
  border: 1px solid #dcdfe6;
  border-radius: 8px;
  font-size: 14px;
  color: #303133;
  font-weight: 500;
  text-align: center;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
}

.port-value:hover {
  border-color: #409EFF;
  box-shadow: 0 4px 8px rgba(64, 158, 255, 0.2);
}

.port-arrow {
  color: #409EFF;
  font-size: 20px;
}

.remark-content {
  padding: 16px;
  background: #f5f7fa;
  border-radius: 8px;
  color: #606266;
  line-height: 1.8;
  white-space: pre-wrap;
}

:deep(.el-descriptions) {
  margin-top: 12px;
}

:deep(.el-descriptions__label) {
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  font-weight: 600;
  color: #606266;
}

:deep(.el-descriptions__content) {
  color: #303133;
}
</style>
