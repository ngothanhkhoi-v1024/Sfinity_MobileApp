import { Router } from 'express';
import { randomUUID } from 'crypto';
import { extname } from 'path';
import { getDownloadURL } from 'firebase-admin/storage';

import { asyncHandler } from '../lib/async-handler';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { upload } from '../lib/upload';
import { getStorageBucket } from '../lib/firebase';
import { logger } from '../lib/logger';

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

    try {
      const bucket = getStorageBucket();
      const id = randomUUID();
      const ext = extname(req.file.originalname).toLowerCase() || '.jpg';
      const fileName = `uploads/${id}${ext}`;
      
      const fileRef = bucket.file(fileName);
      
      logger.info({ fileName, size: req.file.size }, 'Uploading file to Firebase Storage');

      await fileRef.save(req.file.buffer, {
        metadata: {
          contentType: req.file.mimetype,
        },
      });

      const url = await getDownloadURL(fileRef);
      logger.info({ url }, 'File uploaded successfully to Firebase Storage');

      res.json({ url });
    } catch (error) {
      logger.error({ err: error }, 'Failed to upload file to Firebase Storage');
      res.status(500).json({
        message: 'Lỗi tải ảnh lên Cloud Storage.',
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }),
);
