import 'reflect-metadata';
import path from 'path';
import fs from 'fs';
import cors from 'cors';
import express from 'express';
import swaggerUi from 'swagger-ui-express';

import { errorMiddleware } from './middleware/error.middleware';
import { loggingMiddleware } from './middleware/logging.middleware';
import { openApiDocument } from './openapi';
import { apiRouter } from './routes';

export function createApp() {
  const app = express();
  app.use(cors({ origin: true, credentials: true }));
  app.use(express.json());
  app.use(loggingMiddleware);
  app.use('/uploads', express.static('./uploads'));
  
  // Fallback for missing images in uploads directory to prevent frontend loading crashes
  app.use('/uploads', (req, res, next) => {
    const ext = path.extname(req.path).toLowerCase();
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    if (imageExtensions.includes(ext)) {
      const fallbackPath = path.join(__dirname, '../uploads/placeholder.png');
      if (fs.existsSync(fallbackPath)) {
        res.setHeader('Content-Type', 'image/png');
        res.sendFile(fallbackPath);
        return;
      }
    }
    next();
  });

  app.use('/api', apiRouter);
  app.use(
    '/api/docs',
    swaggerUi.serve,
    swaggerUi.setup(openApiDocument as unknown as Record<string, unknown>),
  );
  app.get('/api/openapi.json', (_req, res) => {
    res.json(openApiDocument);
  });
  app.use(errorMiddleware);
  return app;
}
