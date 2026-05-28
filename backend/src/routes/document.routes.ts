import { ContentStatus, UserRole } from '../types/enums';
import { Router } from 'express';

import { CreateDocumentDto, UpdateDocumentDto } from '../dto/document.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { documentService } from '../services/document.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const documentRouter = Router();

documentRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const search = req.query.search as string | undefined;
    const status = req.query.status as ContentStatus | undefined;
    const categoryId = req.query.categoryId as string | undefined;
    const page = req.query.page as string | undefined;
    const limit = req.query.limit as string | undefined;
    const publishedOnly = req.query.publishedOnly as string | undefined;

    res.json(
      await documentService.findAll({
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

documentRouter.post(
  '/',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateDocumentDto, req.body);
    res.json(await documentService.create(req.user!.sub, dto));
  }),
);

documentRouter.patch(
  '/:id/publish',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await documentService.update(
        req.params.id,
        { status: ContentStatus.PUBLISHED },
        '',
        UserRole.ADMIN,
      ),
    );
  }),
);

documentRouter.patch(
  '/:id/unpublish',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await documentService.update(
        req.params.id,
        { status: ContentStatus.DRAFT },
        '',
        UserRole.ADMIN,
      ),
    );
  }),
);

documentRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json(await documentService.findOne(req.params.id));
  }),
);

documentRouter.patch(
  '/:id',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateDocumentDto, req.body);
    res.json(
      await documentService.update(
        req.params.id,
        dto,
        req.user!.sub,
        req.user!.role,
      ),
    );
  }),
);

documentRouter.delete(
  '/:id',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await documentService.remove(req.params.id, req.user!.sub, req.user!.role),
    );
  }),
);
