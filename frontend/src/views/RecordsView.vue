<template>
  <div class="records-view">
    <el-card class="filter-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <el-icon :size="20" color="#409EFF"><Search /></el-icon>
          <span>查询条件</span>
          <el-button type="primary" size="small" :loading="loading" @click="handleSearch">
            <el-icon><Search /></el-icon>
            查询
          </el-button>
          <el-button size="small" @click="handleReset">
            <el-icon><RefreshLeft /></el-icon>
            重置
          </el-button>
          <el-button type="success" size="small" :loading="exporting" @click="handleExport">
            <el-icon><Download /></el-icon>
            导出
          </el-button>
        </div>
      </template>

      <el-form :model="queryParams" label-width="100px" class="filter-form">
        <el-row :gutter="16">
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="机房名称">
              <el-select
                v-model="queryParams.datacenter_name"
                placeholder="请选择机房"
                clearable
                filterable
                style="width: 100%"
              >
                <el-option
                  v-for="dc in filterOptions.datacenters"
                  :key="dc"
                  :label="dc"
                  :value="dc"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="登记表编号">
              <el-input
                v-model="queryParams.record_number"
                placeholder="请输入登记表编号"
                clearable
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="线路编号">
              <el-input
                v-model="queryParams.circuit_number"
                placeholder="请输入线路编号"
                clearable
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="起始端口">
              <el-input v-model="queryParams.start_port" placeholder="请输入起始端口" clearable />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="目标端口">
              <el-input v-model="queryParams.end_port" placeholder="请输入目标端口" clearable />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="用户机柜">
              <el-input v-model="queryParams.user_cabinet" placeholder="请输入用户机柜" clearable />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="运营商">
              <el-select
                v-model="queryParams.operator"
                placeholder="请选择运营商"
                clearable
                filterable
                style="width: 100%"
              >
                <el-option
                  v-for="op in filterOptions.operators"
                  :key="op"
                  :label="op"
                  :value="op"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="线缆类型">
              <el-select
                v-model="queryParams.cable_type"
                placeholder="请选择线缆类型"
                clearable
                filterable
                style="width: 100%"
              >
                <el-option
                  v-for="ct in filterOptions.cableTypes"
                  :key="ct"
                  :label="ct"
                  :value="ct"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="IDC需求编号">
              <el-input
                v-model="queryParams.idc_requirement_number"
                placeholder="请输入IDC需求编号"
                clearable
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="YES工单编号">
              <el-input
                v-model="queryParams.yes_ticket_number"
                placeholder="请输入YES工单编号"
                clearable
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="用户名称">
              <el-input v-model="queryParams.user_unit" placeholder="请输入用户名称" clearable />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card class="table-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <el-icon :size="20" color="#409EFF"><List /></el-icon>
          <span>布线记录列表</span>
          <div class="header-actions">
            <el-tag type="info">共 {{ queryResult.total }} 条记录</el-tag>
            <el-button type="danger" size="small" :icon="Delete" @click="handleClearAll">
              清空所有数据
            </el-button>
          </div>
        </div>
      </template>

      <el-table
        v-loading="loading"
        :data="queryResult.data"
        stripe
        style="width: 100%"
        class="records-table"
        @row-click="handleRowClick"
      >
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column
          prop="record_number"
          label="登记表编号"
          min-width="140"
          show-overflow-tooltip
        />
        <el-table-column
          prop="datacenter_name"
          label="机房名称"
          min-width="120"
          show-overflow-tooltip
        />
        <el-table-column
          prop="circuit_number"
          label="线路编号"
          min-width="140"
          show-overflow-tooltip
        />
        <el-table-column prop="operator" label="运营商" width="100" align="center" />
        <el-table-column prop="start_port" label="起始端口" min-width="120" show-overflow-tooltip />
        <el-table-column prop="end_port" label="目标端口" min-width="120" show-overflow-tooltip />
        <el-table-column
          prop="user_cabinet"
          label="用户机柜"
          min-width="100"
          show-overflow-tooltip
        />
        <el-table-column
          prop="execution_date"
          label="执行时间"
          width="120"
          align="center"
          show-overflow-tooltip
        />
        <el-table-column label="标签齐全" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.label_complete ? 'success' : 'warning'" size="small">
              {{ row.label_complete ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="线路规范" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.cable_standard ? 'success' : 'warning'" size="small">
              {{ row.cable_standard ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180" align="center">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click.stop="handleViewDetail(row.id)"> 详情 </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-container">
        <el-pagination
          v-model:current-page="queryParams.page"
          v-model:page-size="queryParams.page_size"
          :page-sizes="[10, 20, 50, 100]"
          :total="queryResult.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSearch"
          @current-change="handleSearch"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Search, RefreshLeft, List, Delete, Download } from '@element-plus/icons-vue';
import { recordApi } from '@/services/api';
import type { QueryParams, QueryResult, FilterOptions, Record } from '@/types';

const router = useRouter();
const route = useRoute();

const queryParams = ref<QueryParams>({
  page: 1,
  page_size: 20,
});

const queryResult = ref<QueryResult>({
  data: [],
  total: 0,
  page: 1,
  page_size: 20,
});

const filterOptions = ref<FilterOptions>({
  datacenters: [],
  operators: [],
  cableTypes: [],
});

const loading = ref(false);
const exporting = ref(false);

const loadFilterOptions = async () => {
  try {
    const response = await recordApi.getFilterOptions();
    if (response.success && response.data) {
      filterOptions.value = response.data;
    }
  } catch (error) {
    console.error('Failed to load filter options:', error);
  }
};

const handleSearch = async () => {
  loading.value = true;
  try {
    const response = await recordApi.query(queryParams.value);
    if (response.success && response.data) {
      queryResult.value = response.data;
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || '查询失败');
  } finally {
    loading.value = false;
  }
};

const handleReset = () => {
  queryParams.value = {
    page: 1,
    page_size: 20,
  };
  handleSearch();
};

const handleExport = async () => {
  exporting.value = true;
  try {
    const blob = await recordApi.export(queryParams.value);

    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `综合布线记录_${new Date().toISOString().split('T')[0]}.xlsx`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);

    ElMessage.success('导出成功');
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || '导出失败');
  } finally {
    exporting.value = false;
  }
};

const handleRowClick = (row: Record) => {
  handleViewDetail(row.id);
};

const handleViewDetail = (id: number | undefined) => {
  if (id) {
    router.push({
      path: `/records/${id}`,
      query: {
        page: queryParams.value.page,
        page_size: queryParams.value.page_size,
      },
    });
  }
};

const handleClearAll = async () => {
  try {
    await ElMessageBox.confirm('确定要清空所有布线记录吗？此操作不可恢复！', '警告', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    });

    const response = await recordApi.clearAll();
    if (response.success) {
      ElMessage.success('已清空所有数据');
      handleSearch();
      loadFilterOptions();
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.message || '操作失败');
    }
  }
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
  });
};

onMounted(() => {
  const page = route.query.page ? parseInt(route.query.page as string) : 1;
  const pageSize = route.query.page_size ? parseInt(route.query.page_size as string) : 20;

  queryParams.value.page = page;
  queryParams.value.page_size = pageSize;

  loadFilterOptions();
  handleSearch();
});
</script>

<style scoped>
.records-view {
  width: 100%;
  max-width: 1600px;
  margin: 0 auto;
}

.filter-card,
.table-card {
  border-radius: 16px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.header-actions {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 12px;
}

.filter-form {
  padding: 10px 0;
}

.records-table {
  cursor: pointer;
}

:deep(.el-table__row) {
  transition: all 0.3s ease;
}

:deep(.el-table__row:hover) {
  background-color: #f5f7fa !important;
  transform: translateX(4px);
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}
</style>
