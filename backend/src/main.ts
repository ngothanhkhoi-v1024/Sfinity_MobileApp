import { createApp } from './app';
import { config } from './lib/config';
import { prisma } from './lib/prisma';

async function bootstrap() {
  await prisma.$connect();
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
