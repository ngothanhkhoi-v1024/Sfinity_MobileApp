import { ContentModerationStatus, ContentVisibility, UserRole } from '../types/enums';
import { Router } from 'express';

import { AdminApproveDto, AdminDeleteDto, AdminHideDto, AdminUnhideDto } from '../dto/admin-document.dto';
import { CreateDocumentDto, UpdateDocumentDto } from '../dto/document.dto';
import { CreateDocumentReviewDto } from '../dto/document-review.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware, optionalJwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { documentService } from '../services/document.service';
import { documentReviewService } from '../services/document-review.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const documentRouter = Router();

documentRouter.get(
  '/',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const search = req.query.search as string | undefined;

    const categoryId = req.query.categoryId as string | undefined;
    const authorId = req.query.authorId as string | undefined;
    const placeId = req.query.placeId as string | undefined;

    const page = req.query.page as string | undefined;
    const limit = req.query.limit as string | undefined;
    const publishedOnly = req.query.publishedOnly as string | undefined;

    res.json(
      await documentService.findAll({
        search,

        categoryId,
        authorId,
        placeId,

        page: page ? Number(page) : 1,
        limit: limit ? Number(limit) : 20,
        publishedOnly: publishedOnly === 'true',
        viewerId: req.user?.sub,
        viewerRole: req.user?.role,
      }),
    );
  }),
);

documentRouter.post(
  '/',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateDocumentDto, req.body);
    res.json(await documentService.create(req.user!.sub, dto, req.user!.role));
  }),
);

documentRouter.patch(
  '/:id/publish',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await documentService.update(
        req.params.id,
        { visibility: ContentVisibility.PUBLIC, moderationStatus: ContentModerationStatus.APPROVED },
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
        { visibility: ContentVisibility.PRIVATE, moderationStatus: ContentModerationStatus.NONE },
        '',
        UserRole.ADMIN,
      ),
    );
  }),
);

documentRouter.patch(
  '/:id/admin-hide',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(AdminHideDto, req.body);
    res.json(
      await documentService.adminHide(
        req.params.id,
        dto.reason,
      ),
    );
  }),
);

documentRouter.patch(
  '/:id/reject',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(AdminHideDto, req.body);
    res.json(
      await documentService.adminReject(
        req.params.id,
        dto.reason,
      ),
    );
  }),
);

documentRouter.delete(
  '/:id/admin-delete',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(AdminDeleteDto, req.body);
    res.json(
      await documentService.adminDelete(
        req.params.id,
        dto.reason,
      ),
    );
  }),
);

documentRouter.patch(
  '/:id/admin-unhide',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(AdminUnhideDto, req.body);
    res.json(
      await documentService.adminUnhide(
        req.params.id,
        dto.note,
      ),
    );
  }),
);

documentRouter.patch(
  '/:id/approve',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(AdminApproveDto, req.body);
    res.json(
      await documentService.adminApprove(
        req.params.id,
        dto.note,
      ),
    );
  }),
);

documentRouter.get(
  '/:id',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(await documentService.findOne(req.params.id, req.user?.sub, req.user?.role));
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

documentRouter.patch(
  '/:id/download',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(await documentService.incrementDownload(req.params.id, req.user?.sub, req.user?.role));
  }),
);

documentRouter.get(
  '/:id/reviews',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    await documentService.findOne(req.params.id, req.user?.sub, req.user?.role);
    res.json(await documentReviewService.list(req.params.id));
  }),
);

documentRouter.post(
  '/:id/reviews',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    await documentService.findOne(req.params.id, req.user!.sub, req.user!.role);
    const dto = await validateBody(CreateDocumentReviewDto, req.body);
    res.json(await documentReviewService.upsert(req.params.id, req.user!.sub, dto));
  }),
);

documentRouter.delete(
  '/:id/reviews',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    await documentService.findOne(req.params.id, req.user!.sub, req.user!.role);
    res.json(await documentReviewService.remove(req.params.id, req.user!.sub));
  }),
);


