import { ContentStatus, UserRole } from '@prisma/client';
import { Router } from 'express';

import { CreateContentDto, UpdateContentDto } from '../dto/content.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { contentService } from '../services/content.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const contentRouter = Router();

contentRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const search = req.query.search as string | undefined;
    const status = req.query.status as ContentStatus | undefined;
    const categoryId = req.query.categoryId as string | undefined;
    const page = req.query.page as string | undefined;
    const limit = req.query.limit as string | undefined;
    const publishedOnly = req.query.publishedOnly as string | undefined;

    res.json(
      await contentService.findAll({
        search,
        status,
        categoryId,
        page: page ? Number(page) : 1,
        limit: limit ? Number(limit) : 20,
        publishedOnly: publishedOnly === 'true',
      }),
    );
  }),
);

contentRouter.post(
  '/',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateContentDto, req.body);
    res.json(await contentService.create(req.user!.sub, dto));
  }),
);

contentRouter.patch(
  '/:id/publish',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await contentService.update(
        req.params.id,
        { status: ContentStatus.PUBLISHED },
        '',
        UserRole.ADMIN,
      ),
    );
  }),
);

contentRouter.patch(
  '/:id/unpublish',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await contentService.update(
        req.params.id,
        { status: ContentStatus.DRAFT },
        '',
        UserRole.ADMIN,
      ),
    );
  }),
);

contentRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json(await contentService.findOne(req.params.id));
  }),
);

contentRouter.patch(
  '/:id',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateContentDto, req.body);
    res.json(
      await contentService.update(
        req.params.id,
        dto,
        req.user!.sub,
        req.user!.role,
      ),
    );
  }),
);

contentRouter.delete(
  '/:id',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await contentService.remove(req.params.id, req.user!.sub, req.user!.role),
    );
  }),
);
