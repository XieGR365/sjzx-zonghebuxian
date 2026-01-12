import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import { RecordController } from '../controllers/RecordController';

const router = Router();

const storage = multer.memoryStorage();
const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (ext !== '.xlsx' && ext !== '.xls') {
      return cb(new Error('只支持Excel文件'));
    }
    cb(null, true);
  },
  limits: {
    fileSize: 10 * 1024 * 1024
  }
});

router.post('/upload', upload.single('file'), RecordController.upload);
router.get('/query', RecordController.query);
router.get('/detail/:id', RecordController.getDetail);
router.put('/update/:id', RecordController.update);
router.delete('/delete/:id', RecordController.delete);
router.post('/batch-delete', RecordController.batchDelete);
router.delete('/clear', RecordController.clearAll);
router.get('/datacenters', RecordController.getDatacenters);
router.get('/filter-options', RecordController.getFilterOptions);
router.get('/export', RecordController.export);
router.get('/statistics', RecordController.getStatistics);
router.get('/statistics/datacenters', RecordController.getDatacenterStatistics);
router.get('/statistics/jump-fiber', RecordController.getJumpFiberStatistics);
router.get('/statistics/jump-fiber/export', RecordController.exportJumpFiberStatistics);

export default router;
