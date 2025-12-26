import { Router } from 'express';
import { SavedQueryController } from '../controllers/SavedQueryController';

const router = Router();

router.post('/', SavedQueryController.create);
router.get('/', SavedQueryController.query);
router.get('/:id', SavedQueryController.getById);
router.put('/:id', SavedQueryController.update);
router.delete('/:id', SavedQueryController.delete);

export default router;
