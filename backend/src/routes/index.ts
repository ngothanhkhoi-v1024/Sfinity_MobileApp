import { Router } from 'express';

import { authRouter } from './auth.routes';
import { categoriesRouter } from './categories.routes';
import { contentRouter } from './content.routes';
import { dashboardRouter } from './dashboard.routes';
import { favoritesRouter } from './favorites.routes';
import { feedbackRouter } from './feedback.routes';
import { notificationsRouter } from './notifications.routes';
import { reportsRouter } from './reports.routes';
import { usersRouter } from './users.routes';

export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/users', usersRouter);
apiRouter.use('/categories', categoriesRouter);
apiRouter.use('/content', contentRouter);
apiRouter.use('/favorites', favoritesRouter);
apiRouter.use('/feedback', feedbackRouter);
apiRouter.use('/reports', reportsRouter);
apiRouter.use('/notifications', notificationsRouter);
apiRouter.use('/admin/dashboard', dashboardRouter);
