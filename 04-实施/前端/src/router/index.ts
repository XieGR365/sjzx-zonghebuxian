import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/upload'
  },
  {
    path: '/upload',
    name: 'Upload',
    component: () => import('@/views/UploadView.vue'),
    meta: { title: '上传文件' }
  },
  {
    path: '/records',
    name: 'Records',
    component: () => import('@/views/RecordsView.vue'),
    meta: { title: '布线记录' }
  },
  {
    path: '/records/:id',
    name: 'RecordDetail',
    component: () => import('@/views/RecordDetailView.vue'),
    meta: { title: '记录详情' }
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

router.beforeEach((to, from, next) => {
  document.title = `${to.meta.title || '综合布线记录管理系统'} - 综合布线记录管理系统`;
  next();
});

export default router;
