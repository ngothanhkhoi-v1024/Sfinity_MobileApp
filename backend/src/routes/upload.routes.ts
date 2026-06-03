import { Router } from 'express';
import { asyncHandler } from '../lib/async-handler';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { upload } from '../lib/upload';
import { config } from '../lib/config';

export const uploadRouter = Router();

uploadRouter.post(
  '/image',
  jwtAuthMiddleware,
  upload.single('file'),
  asyncHandler(async (req, res) => {
    if (!req.file) {
      res.status(400).json({ message: 'Không có file nào được gửi lên.' });
      return;
    }
    const baseUrl = config.apiBaseUrl.replace(/\/api$/, '');
    const url = `${baseUrl}/uploads/${req.file.filename}`;
    res.json({ url });
  }),
);
