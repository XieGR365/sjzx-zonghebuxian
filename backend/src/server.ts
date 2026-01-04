import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import recordRoutes from './routes/recordRoutes';
import operationLogRoutes from './routes/operationLogRoutes';
import savedQueryRoutes from './routes/savedQueryRoutes';
import exportHistoryRoutes from './routes/exportHistoryRoutes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/records', recordRoutes);
app.use('/api/operation-logs', operationLogRoutes);
app.use('/api/saved-queries', savedQueryRoutes);
app.use('/api/export-history', exportHistoryRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: '综合布线记录管理系统后端服务正常运行' });
});

app.use((req, res) => {
  res.status(404).json({ success: false, message: '接口不存在' });
});

app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Server error:', err);
  res.status(500).json({ success: false, message: '服务器内部错误' });
});

app.listen(PORT, () => {
  console.log(`综合布线记录管理系统后端服务已启动`);
  console.log(`服务地址: http://localhost:${PORT}`);
  console.log(`健康检查: http://localhost:${PORT}/health`);
});

export default app;
