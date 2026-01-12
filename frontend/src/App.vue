<template>
  <div id="app">
    <el-container class="app-container">
      <el-header class="app-header">
        <div class="header-content">
          <div class="logo">
            <el-icon :size="28" color="#409EFF">
              <Connection />
            </el-icon>
            <span class="title">综合布线记录管理系统</span>
          </div>
          <nav class="nav">
            <router-link to="/upload" class="nav-item" active-class="active">
              <el-icon><Upload /></el-icon>
              <span>上传文件</span>
            </router-link>
            <router-link to="/records" class="nav-item" active-class="active">
              <el-icon><List /></el-icon>
              <span>布线记录</span>
            </router-link>
            <router-link to="/statistics/jump-fiber" class="nav-item" active-class="active">
              <el-icon><DataAnalysis /></el-icon>
              <span>跳纤统计</span>
            </router-link>
          </nav>
        </div>
      </el-header>
      <el-main class="app-main">
        <router-view />
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { Connection, Upload, List, DataAnalysis } from '@element-plus/icons-vue';
</script>

<style scoped>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

#app {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.app-container {
  min-height: 100vh;
}

.app-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  box-shadow: 0 2px 20px rgba(0, 0, 0, 0.1);
  padding: 0;
  height: 64px !important;
  display: flex;
  align-items: center;
  justify-content: center;
}

.header-content {
  width: 100%;
  max-width: 1400px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
}

.title {
  font-size: 20px;
  font-weight: 600;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.nav {
  display: flex;
  gap: 8px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 20px;
  border-radius: 8px;
  color: #606266;
  text-decoration: none;
  transition: all 0.3s ease;
  font-weight: 500;
}

.nav-item:hover {
  background: #f5f7fa;
  color: #409EFF;
}

.nav-item.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.app-main {
  padding: 24px;
  display: flex;
  justify-content: center;
}
</style>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

#app {
  min-height: 100vh;
}
</style>
