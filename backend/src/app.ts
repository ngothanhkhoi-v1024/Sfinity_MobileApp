import 'reflect-metadata';
import cors from 'cors';
import express from 'express';
import swaggerUi from 'swagger-ui-express';

import { errorMiddleware } from './middleware/error.middleware';
import { openApiDocument } from './openapi';
import { apiRouter } from './routes';

export function createApp() {
  const app = express();
  app.use(cors({ origin: true, credentials: true }));
  app.use(express.json());
  app.use('/uploads', express.static('./uploads'));
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
