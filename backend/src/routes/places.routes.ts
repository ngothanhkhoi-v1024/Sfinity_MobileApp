import { Router } from 'express';

import { PLACE_ZONES } from '../constants/place-zones';
import { CreatePlaceCheckInDto } from '../dto/place-checkin.dto';
import { CreatePlacePhotoDto } from '../dto/place-photo.dto';
import { CreatePlaceReviewDto } from '../dto/place-review.dto';
import { CreatePlaceDto, UpdatePlaceDto } from '../dto/place.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware, optionalJwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { placeService } from '../services/place.service';
import { placeCheckInService } from '../services/place-checkin.service';
import { placePhotoService } from '../services/place-photo.service';
import { placeReviewService } from '../services/place-review.service';
import { weatherService } from '../services/weather.service';
import { HttpError } from '../lib/http-error';
import {
  ContentModerationStatus,
  ContentVisibility,
  UserRole,
} from '../types/enums';

export const placesRouter = Router();

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

placesRouter.get(
  '/zones',
  asyncHandler(async (_req, res) => {
    res.json({ zones: PLACE_ZONES });
  }),
);

placesRouter.get(
  '/',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const search = req.query.search as string | undefined;
    const visibility = req.query.visibility as ContentVisibility | undefined;
    const moderationStatus = req.query.moderationStatus as
      | ContentModerationStatus
      | undefined;
    const authorId = req.query.authorId as string | undefined;
    const tags = req.query.tags as string | undefined;
    const zone = req.query.zone as string | undefined;
    const lat = req.query.lat as string | undefined;
    const lng = req.query.lng as string | undefined;
    const radiusKm = req.query.radiusKm as string | undefined;
    const minRating = req.query.minRating as string | undefined;
    const page = req.query.page as string | undefined;
    const limit = req.query.limit as string | undefined;
    const publishedOnly = req.query.publishedOnly as string | undefined;

    res.json(
      await placeService.findAll({
        search,
        visibility,
        moderationStatus,
        authorId,
        tags,
        zone,
        lat: lat != null ? Number(lat) : undefined,
        lng: lng != null ? Number(lng) : undefined,
        radiusKm: radiusKm != null ? Number(radiusKm) : undefined,
        minRating: minRating != null ? Number(minRating) : undefined,
        page: page ? Number(page) : 1,
        limit: limit ? Number(limit) : 20,
        publishedOnly: publishedOnly === 'true',
        viewerId: req.user?.sub,
        viewerRole: req.user?.role,
      }),
    );
  }),
);

placesRouter.post(
  '/',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreatePlaceDto, req.body);
    res.json(await placeService.create(req.user!.sub, dto, req.user!.role));
  }),
);

placesRouter.get(
  '/:id',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.findOne(req.params.id, req.user?.sub, req.user?.role),
    );
  }),
);

placesRouter.get(
  '/:id/weather',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const place = await placeService.findOne(
      req.params.id,
      req.user?.sub,
      req.user?.role,
    );
    const lat = place.latitude;
    const lng = place.longitude;
    if (typeof lat !== 'number' || typeof lng !== 'number') {
      throw new HttpError(
        404,
        'Địa điểm chưa có tọa độ.',
        'Not Found',
      );
    }
    res.json(await weatherService.getCurrentWeather(lat, lng));
  }),
);

placesRouter.patch(
  '/:id',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdatePlaceDto, req.body);
    res.json(
      await placeService.update(
        req.params.id,
        dto,
        req.user!.sub,
        req.user!.role,
      ),
    );
  }),
);

placesRouter.delete(
  '/:id',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.remove(req.params.id, req.user!.sub, req.user!.role),
    );
  }),
);

// Admin Moderation for Places
placesRouter.patch(
  '/:id/publish',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.update(
        req.params.id,
        {
          visibility: ContentVisibility.PUBLIC,
          moderationStatus: ContentModerationStatus.APPROVED,
        },
        '',
        UserRole.ADMIN,
      ),
    );
  }),
);

placesRouter.patch(
  '/:id/unpublish',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.update(
        req.params.id,
        {
          visibility: ContentVisibility.PRIVATE,
          moderationStatus: ContentModerationStatus.NONE,
        },
        '',
        UserRole.ADMIN,
      ),
    );
  }),
);

placesRouter.patch(
  '/:id/admin-hide',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.adminHide(
        req.params.id,
        req.body.reason || '',
      ),
    );
  }),
);

placesRouter.patch(
  '/:id/reject',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.adminReject(
        req.params.id,
        req.body.reason || '',
      ),
    );
  }),
);

placesRouter.delete(
  '/:id/admin-delete',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.adminDelete(
        req.params.id,
        req.body.reason || '',
      ),
    );
  }),
);

placesRouter.patch(
  '/:id/admin-unhide',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.adminUnhide(
        req.params.id,
        req.body.note || '',
      ),
    );
  }),
);

placesRouter.patch(
  '/:id/approve',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(
      await placeService.adminApprove(
        req.params.id,
        req.body.note || '',
      ),
    );
  }),
);

// Place Check-Ins, Reviews, and Photos routes
placesRouter.get(
  '/:placeId/check-ins/status',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await placeCheckInService.getStatus(
        req.params.placeId,
        req.user?.sub,
      ),
    );
  }),
);

placesRouter.post(
  '/:placeId/check-ins',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreatePlaceCheckInDto, req.body);
    res.status(201).json(
      await placeCheckInService.checkIn(
        req.params.placeId,
        req.user!.sub,
        dto,
      ),
    );
  }),
);

placesRouter.get(
  '/:placeId/reviews',
  asyncHandler(async (req, res) => {
    res.json(await placeReviewService.list(req.params.placeId));
  }),
);

placesRouter.post(
  '/:placeId/reviews',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreatePlaceReviewDto, req.body);
    res.json(
      await placeReviewService.upsert(req.params.placeId, req.user!.sub, dto),
    );
  }),
);

placesRouter.get(
  '/:placeId/photos',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await placePhotoService.list(
        req.params.placeId,
        30,
        req.user?.sub,
        req.user?.role,
      ),
    );
  }),
);

placesRouter.post(
  '/:placeId/photos',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreatePlacePhotoDto, req.body);
    res.json(
      await placePhotoService.create(
        req.params.placeId,
        req.user!.sub,
        dto,
        req.user!.role,
      ),
    );
  }),
);

placesRouter.delete(
  '/:placeId/photos/:photoId',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await placePhotoService.remove(
        req.params.photoId,
        req.user!.sub,
        req.user!.role,
      ),
    );
  }),
);
