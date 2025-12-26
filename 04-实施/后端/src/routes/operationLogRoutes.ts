import { Router } from 'express';
import { OperationLogController } from '../controllers/OperationLogController';

const router = Router();

router.get('/query', OperationLogController.query);
router.get('/statistics', OperationLogController.getStatistics);
router.get('/export', OperationLogController.export);
router.delete('/delete-old', OperationLogController.deleteOldLogs);

export default router;
