import { createApp } from './app';
import { config } from './lib/config';
import { isFirebaseReady } from './lib/firebase';
import { seedAmenities } from './services/amenities.service';

async function bootstrap() {
  if (!isFirebaseReady()) {
    console.warn('WARNING: Firebase is not fully configured. Please check your environment variables.');
  } else {
    console.log('Firebase Admin SDK is fully configured and ready.');
    try {
      await seedAmenities();
      console.log('Amenities initialized successfully.');
    } catch (e) {
      console.error('Failed to initialize amenities:', e);
    }
  }

  const app = createApp();
  const port = config.port;
  app.listen(port, () => {
    console.log(`API: http://localhost:${port}/api`);
    console.log(`Swagger: http://localhost:${port}/api/docs`);
  });
}

bootstrap().catch((e) => {
  console.error(e);
  process.exit(1);
});
