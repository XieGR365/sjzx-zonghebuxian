import { Router } from 'express';
import { ExportHistoryController } from '../controllers/ExportHistoryController';

const router = Router();

router.get('/query', ExportHistoryController.query);
router.get('/statistics', ExportHistoryController.getStatistics);
router.delete('/delete-old', ExportHistoryController.deleteOldHistory);

export default router;
