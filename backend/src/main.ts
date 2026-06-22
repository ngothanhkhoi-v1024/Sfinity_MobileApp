import { createApp } from './app';
import { config } from './lib/config';
import { isFirebaseReady } from './lib/firebase';
import { logger } from './lib/logger';
import { seedAmenities } from './services/amenities.service';

// Register process listeners for global uncaught exception/rejection handling
process.on('uncaughtException', (err) => {
  logger.fatal({
    msg: 'Uncaught Exception! Server is shutting down...',
    err: { message: err.message, stack: err.stack },
  });
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error({
    msg: 'Unhandled Promise Rejection detected',
    promise,
    reason: reason instanceof Error ? { message: reason.message, stack: reason.stack } : reason,
  });
});

async function bootstrap() {
  if (!isFirebaseReady()) {
    logger.warn('WARNING: Firebase is not fully configured. Please check your environment variables.');
  } else {
    logger.info('Firebase Admin SDK is fully configured and ready.');
    try {
      await seedAmenities();
      logger.info('Amenities initialized successfully.');
    } catch (e) {
      logger.error({ msg: 'Failed to initialize amenities', err: e });
    }
  }

  const app = createApp();
  const port = config.port;
  app.listen(port, () => {
    logger.info(`API: http://localhost:${port}/api`);
    logger.info(`Swagger: http://localhost:${port}/api/docs`);
  });
}

bootstrap().catch((e) => {
  logger.fatal({ msg: 'Bootstrap failed', err: e });
  process.exit(1);
});
