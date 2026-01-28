<template>
  <div class="jump-fiber-statistics">
    <div class="page-header">
      <h1>综合布线跳纤统计</h1>
      <div class="header-actions">
        <el-button type="primary" @click="exportStatistics">
          <el-icon><Download /></el-icon>
          导出报表
        </el-button>
        <el-button @click="refreshData">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
      </div>
    </div>

    <el-card class="filter-card" shadow="hover">
      <el-form :inline="true" :model="filters" class="filter-form">
        <el-form-item label="机房名称">
          <el-select
            v-model="filters.datacenter"
            placeholder="全部机房"
            clearable
            style="width: 200px"
          >
            <el-option label="全部机房" value="" />
            <el-option
              v-for="dc in datacenters"
              :key="dc"
              :label="dc"
              :value="dc"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="线路状态">
          <el-select
            v-model="filters.status"
            placeholder="全部状态"
            clearable
            style="width: 150px"
          >
            <el-option label="全部状态" value="" />
            <el-option label="在用" value="inUse" />
            <el-option label="已拆除" value="removed" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="applyFilters">
            <el-icon><Search /></el-icon>
            筛选
          </el-button>
          <el-button @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <div v-if="loading" class="loading-container">
      <el-icon class="is-loading" :size="40"><Loading /></el-icon>
      <p>加载中...</p>
    </div>

    <div v-else-if="filteredDatacenters.length === 0" class="empty-container">
      <el-empty description="暂无数据" />
    </div>

    <div v-else class="statistics-grid">
      <el-collapse v-model="activeDatacenters" accordion>
        <el-collapse-item
          v-for="stat in filteredDatacenters"
          :key="stat.datacenter"
          :name="stat.datacenter"
        >
          <template #title>
            <div class="collapse-title">
              <el-icon :size="24" color="#409EFF"><OfficeBuilding /></el-icon>
              <span class="datacenter-name">{{ stat.datacenter }}</span>
              <el-tag type="info" size="small">共 {{ stat.total }} 条</el-tag>
            </div>
          </template>
          
          <div class="statistics-content">
            <div class="total-section" @click.stop="viewDatacenterDetails(stat.datacenter, '')">
              <div class="total-label">跳纤总数</div>
              <div class="total-value">{{ stat.total }}</div>
            </div>
            
            <div class="status-section">
              <div class="status-item in-use" @click.stop="viewDatacenterDetails(stat.datacenter, 'inUse')">
                <div class="status-header">
                  <span class="status-label">在用线路</span>
                  <el-tag type="success" size="small">{{ stat.inUse }}</el-tag>
                </div>
                <el-progress
                  :percentage="stat.inUseRate"
                  :color="'#67C23A'"
                  :stroke-width="8"
                  :show-text="false"
                />
                <div class="status-rate">{{ stat.inUseRate }}%</div>
              </div>
              
              <div class="status-item removed" @click.stop="viewDatacenterDetails(stat.datacenter, 'removed')">
                <div class="status-header">
                  <span class="status-label">已拆除线路</span>
                  <el-tag type="danger" size="small">{{ stat.removed }}</el-tag>
                </div>
                <el-progress
                  :percentage="stat.removedRate"
                  :color="'#F56C6C'"
                  :stroke-width="8"
                  :show-text="false"
                />
                <div class="status-rate">{{ stat.removedRate }}%</div>
              </div>
            </div>
            
            <div class="detail-section" v-if="expandedDatacenter === stat.datacenter && expandedStatus !== ''">
              <div class="detail-header">
                <span>{{ getStatusText(expandedStatus) }}</span>
                <el-button type="text" size="small" @click.stop="closeDetail">关闭</el-button>
              </div>
              <el-table
                :data="getDetailRecords(stat.datacenter, expandedStatus)"
                v-loading="detailLoading"
                stripe
                border
                size="small"
                style="width: 100%"
              >
                <el-table-column prop="record_number" label="记录编号" width="120" />
                <el-table-column prop="circuit_number" label="电路编号" width="120" />
                <el-table-column prop="start_port" label="起始端口" width="120" />
                <el-table-column prop="end_port" label="终止端口" width="120" />
                <el-table-column prop="user_cabinet" label="用户机柜" width="100" />
                <el-table-column prop="user_unit" label="使用单位" width="120" />
                <el-table-column prop="operator" label="运营商" width="80" />
                <el-table-column prop="execution_date" label="执行日期" width="100" />
                <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
              </el-table>
              
              <el-pagination
                v-if="getDetailPagination(stat.datacenter, expandedStatus).total > 0"
                v-model:current-page="getDetailPagination(stat.datacenter, expandedStatus).page"
                v-model:page-size="getDetailPagination(stat.datacenter, expandedStatus).page_size"
                :page-sizes="[10, 20, 50]"
                :total="getDetailPagination(stat.datacenter, expandedStatus).total"
                layout="total, sizes, prev, pager, next"
                @size-change="(size: number) => handlePageSizeChange(stat.datacenter, size)"
                @current-change="(page: number) => handlePageChange(stat.datacenter, page)"
                style="margin-top: 16px; justify-content: flex-end"
                small
              />
            </div>
          </div>
        </el-collapse-item>
      </el-collapse>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { ElMessage } from 'element-plus';
import { Download, Refresh, Search, Loading, OfficeBuilding } from '@element-plus/icons-vue';
import { recordApi } from '@/services/api';
import type { Record } from '@/types';

interface JumpFiberStat {
  datacenter: string;
  total: number;
  inUse: number;
  removed: number;
  inUseRate: number;
  removedRate: number;
}

interface JumpFiberStatistics {
  datacenters: JumpFiberStat[];
  total: number;
  totalInUse: number;
  totalRemoved: number;
  timestamp: string;
}

const loading = ref(false);
const statistics = ref<JumpFiberStatistics | null>(null);
const filters = ref({
  datacenter: '',
  status: ''
});

const activeDatacenters = ref<string[]>([]);
const expandedDatacenter = ref('');
const expandedStatus = ref('');
const detailLoading = ref(false);
const datacenterRecordsMap = ref<Map<string, Record[]>>(new Map());
const datacenterPaginationMap = ref<Map<string, { page: number; page_size: number; total: number }>>(new Map());

const datacenters = computed(() => {
  if (!statistics.value) return [];
  return statistics.value.datacenters.map(stat => stat.datacenter);
});

const filteredDatacenters = computed(() => {
  if (!statistics.value) return [];
  
  let result = statistics.value.datacenters;
  
  if (filters.value.datacenter) {
    result = result.filter(stat => stat.datacenter === filters.value.datacenter);
  }
  
  if (filters.value.status === 'inUse') {
    result = result.filter(stat => stat.inUse > 0);
  } else if (filters.value.status === 'removed') {
    result = result.filter(stat => stat.removed > 0);
  }
  
  return result;
});

const getStatusText = (status: string) => {
  if (status === 'inUse') return '在用线路';
  if (status === 'removed') return '已拆除线路';
  return '全部线路';
};

const getDetailRecords = (datacenter: string, status: string) => {
  const key = `${datacenter}-${status}`;
  return datacenterRecordsMap.value.get(key) || [];
};

const getDetailPagination = (datacenter: string, status: string) => {
  const key = `${datacenter}-${status}`;
  return datacenterPaginationMap.value.get(key) || { page: 1, page_size: 10, total: 0 };
};

const loadStatistics = async () => {
  loading.value = true;
  try {
    const response = await recordApi.getJumpFiberStatistics();
    if (response.success) {
      statistics.value = response.data;
    } else {
      ElMessage.error(response.message || '加载统计数据失败');
    }
  } catch (error) {
    console.error('Load statistics error:', error);
    ElMessage.error('加载统计数据失败');
  } finally {
    loading.value = false;
  }
};

const loadDetailRecords = async (datacenter: string, status: string) => {
  if (!datacenter) return;
  
  detailLoading.value = true;
  try {
    const queryParams: any = {
      datacenter_name: datacenter,
      page: 1,
      page_size: 10
    };
    
    if (status) {
      queryParams.status = status;
    }
    
    const response = await recordApi.query(queryParams);
    
    if (response.success && response.data) {
      const key = `${datacenter}-${status}`;
      datacenterRecordsMap.value.set(key, response.data.data);
      datacenterPaginationMap.value.set(key, {
        page: response.data.page,
        page_size: response.data.page_size,
        total: response.data.total
      });
    } else {
      ElMessage.error(response.message || '加载详细数据失败');
    }
  } catch (error) {
    console.error('Load detail records error:', error);
    ElMessage.error('加载详细数据失败');
  } finally {
    detailLoading.value = false;
  }
};

const applyFilters = () => {
};

const resetFilters = () => {
  filters.value = {
    datacenter: '',
    status: ''
  };
};

const refreshData = () => {
  loadStatistics();
  ElMessage.success('数据已刷新');
};

const handlePageSizeChange = (datacenter: string, size: number) => {
  const key = `${datacenter}-${expandedStatus.value}`;
  const pagination = datacenterPaginationMap.value.get(key);
  if (pagination) {
    pagination.page_size = size;
    loadDetailRecords(datacenter, expandedStatus.value);
  }
};

const handlePageChange = (datacenter: string, page: number) => {
  const key = `${datacenter}-${expandedStatus.value}`;
  const pagination = datacenterPaginationMap.value.get(key);
  if (pagination) {
    pagination.page = page;
    loadDetailRecords(datacenter, expandedStatus.value);
  }
};

const closeDetail = () => {
  expandedDatacenter.value = '';
  expandedStatus.value = '';
};

const viewDatacenterDetails = (datacenter: string, status: string) => {
  expandedDatacenter.value = datacenter;
  expandedStatus.value = status;
  
  loadDetailRecords(datacenter, status);
};

const exportStatistics = async () => {
  try {
    ElMessage.info('正在导出报表，请稍候...');
    
    const blob = await recordApi.exportJumpFiberStatistics();
    
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `跳纤统计报表_${new Date().toISOString().split('T')[0]}.xlsx`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
    
    ElMessage.success('报表导出成功');
  } catch (error) {
    console.error('Export statistics error:', error);
    ElMessage.error('报表导出失败');
  }
};

onMounted(() => {
  loadStatistics();
});
</script>

<style scoped>
.jump-fiber-statistics {
  padding: 24px;
  background: linear-gradient(135deg, #f5f7fa 0%, #ffffff 100%);
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.page-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 600;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.filter-card {
  margin-bottom: 24px;
}

.filter-form {
  margin: 0;
}

.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 0;
  color: #909399;
}

.loading-container p {
  margin-top: 16px;
  font-size: 16px;
}

.empty-container {
  padding: 60px 0;
}

.statistics-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

:deep(.el-collapse) {
  border: none;
}

:deep(.el-collapse-item) {
  border: none;
  margin-bottom: 0;
}

:deep(.el-collapse-item__header) {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  padding: 20px 24px;
  height: auto;
  line-height: normal;
  color: #ffffff;
  font-size: 0;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
}

:deep(.el-collapse-item__header:hover) {
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
  transform: translateY(-2px);
}

:deep(.el-collapse-item__wrap) {
  background: #ffffff;
  border: none;
  border-radius: 0 0 12px 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  margin-top: -8px;
  overflow: hidden;
}

:deep(.el-collapse-item__content) {
  padding: 24px;
}

:deep(.el-collapse-item__arrow) {
  color: #ffffff;
  font-size: 20px;
  margin-right: 16px;
}

.collapse-title {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
  width: 100%;
}

.datacenter-name {
  flex: 1;
  font-size: 20px;
  font-weight: 700;
}

:deep(.el-tag--info) {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.3);
  color: #ffffff;
  font-weight: 500;
}

.statistics-content {
  padding: 0;
}

.total-section {
  text-align: center;
  padding: 24px 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  margin-bottom: 24px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
}

.total-section:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);
}

.total-label {
  font-size: 15px;
  color: rgba(255, 255, 255, 0.9);
  margin-bottom: 12px;
  font-weight: 500;
  letter-spacing: 0.5px;
}

.total-value {
  font-size: 56px;
  font-weight: 700;
  color: #ffffff;
  line-height: 1;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.status-section {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.status-item {
  padding: 20px;
  border-radius: 12px;
  background: #ffffff;
  border: 2px solid #e4e7ed;
  transition: all 0.3s ease;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.status-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}

.status-item.in-use:hover {
  border-color: #67C23A;
  background: linear-gradient(135deg, #f0f9ff 0%, #e8f4ff 100%);
}

.status-item.removed:hover {
  border-color: #F56C6C;
  background: linear-gradient(135deg, #fef0f0 0%, #fee 100%);
}

.status-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.status-label {
  font-size: 15px;
  color: #606266;
  font-weight: 600;
}

:deep(.el-tag--success) {
  font-size: 14px;
  font-weight: 600;
  padding: 6px 12px;
}

:deep(.el-tag--danger) {
  font-size: 14px;
  font-weight: 600;
  padding: 6px 12px;
}

.status-rate {
  text-align: right;
  font-size: 14px;
  color: #909399;
  margin-top: 8px;
  font-weight: 500;
}

:deep(.el-progress-bar__outer) {
  background-color: #e4e7ed;
  border-radius: 6px;
  height: 10px !important;
}

:deep(.el-progress-bar__inner) {
  border-radius: 6px;
  transition: width 0.6s ease;
}

.detail-section {
  margin-top: 28px;
  padding: 24px;
  background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%);
  border-radius: 12px;
  border: 2px solid #e4e7ed;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 2px solid #e4e7ed;
}

.detail-header span {
  font-size: 17px;
  font-weight: 700;
  color: #303133;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

:deep(.el-button--text) {
  font-weight: 600;
  color: #667eea;
}

:deep(.el-button--text:hover) {
  color: #764ba2;
}

:deep(.el-table) {
  border-radius: 8px;
  overflow: hidden;
}

:deep(.el-table th) {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #ffffff;
  font-weight: 600;
}

:deep(.el-table--striped .el-table__body tr.el-table__row--striped td) {
  background: #f8f9fa;
}

:deep(.el-pagination) {
  display: flex;
  justify-content: flex-end;
  align-items: center;
}

:deep(.el-pagination.is-background .el-pager li:not(.disabled).active) {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #ffffff;
}

:deep(.el-pagination.is-background .el-pager li:not(.disabled):hover) {
  color: #667eea;
}
</style>